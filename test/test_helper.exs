# OTP 18 doesn't support the memory measurement things we need
otp_release = List.to_integer(:erlang.system_info(:otp_release))
exclusions = if otp_release > 18, do: [], else: [memory_measure: true]

# On Windows we have by far worse time measurements (millisecond level)
# see: https://github.com/bencheeorg/benchee/pull/195#issuecomment-377010006
{_, os} = :os.type()

# mac and windows just aren't as fast
exclusions =
  case os do
    :nt ->
      [{:performance, true} | exclusions]

    :darwin ->
      [{:performance, true} | exclusions]

    _ ->
      exclusions
  end

# Somehow at some point the resolution on the Windows CI got very bad to 100 (which is 10ms)
# and so we gotta get some level in here not to work around them too much.
clock_resolution = Access.get(:erlang.system_info(:os_monotonic_time_source), :resolution)

minimum_millisecond_resolution = 1000

exclusions =
  if clock_resolution < minimum_millisecond_resolution do
    [{:minimum_millisecond_resolution_clock, true} | exclusions]
  else
    exclusions
  end

# to trigger fast function repetition we'd need to have a clock with a at most a resolution of
# ~100ns
ns_100_resolution = 10_000_000

exclusions =
  if clock_resolution > ns_100_resolution do
    [{:needs_fast_function_repetition, true} | exclusions]
  else
    exclusions
  end

# to trigger fast function repetition we'd need to have a clock with a at most a resolution of
# ~100ns
ns_resolution = 1_000_000_000

exclusions =
  if clock_resolution < ns_resolution do
    [{:nanosecond_resolution_clock, true} | exclusions]
  else
    exclusions
  end

# somehow on CI macos doesn't have the JIT enabled installed via brew: https://github.com/bencheeorg/benchee/pull/426
exclusions =
  case os do
    :darwin ->
      [{:guaranteed_jit, true} | exclusions]

    _ ->
      exclusions
  end

ExUnit.start(exclude: exclusions)
