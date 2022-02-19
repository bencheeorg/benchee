# OTP 18 doesn't support the memory measurement things we need
otp_release = List.to_integer(:erlang.system_info(:otp_release))
exclusions = if otp_release > 18, do: [], else: [memory_measure: true]

# On Windows we have by far worse time measurements (millisecond level)
# see: https://github.com/PragTob/benchee/pull/195#issuecomment-377010006
{_, os} = :os.type()

exclusions =
  case os do
    :nt ->
      [{:performance, true}, {:nanosecond_resolution_clock, true}] ++ exclusions

    :darwin ->
      [{:performance, true} | exclusions]

    _ ->
      # with our new nanosecond accuracy we can't trigger our super fast function code
      # anymore on Linux and MacOS (see above)
      [{:needs_fast_function_repetition, true} | exclusions]
  end

# Somehow at some point the resolution on the Windows CI got very bad to 100 (which is 10ms)
# and so we gotta get some level in here not to work around them too much.
clock_resolution = Access.get(:erlang.system_info(:os_monotonic_time_source), :resolution)

minimum_millisecond_resolution = 1000

exclusions =
  if clock_resolution < minimum_millisecond_resolution do
    [{:millisecond_resolution_clock, true} | exclusions]
  else
    exclusions
  end

ExUnit.start(exclude: exclusions)
