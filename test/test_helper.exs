# OTP 18 doesn't support the memory measurement things we need
otp_release = List.to_integer(:erlang.system_info(:otp_release))
exclusions = if otp_release > 18, do: [], else: [memory_measure: true]

# See #234
exclusions = if otp_release >= 21 do
               [{:otp_21_memory_problems, true} | exclusions]
             else
               exclusions
             end

# On Windows we have by far worse time measurements (millisecond level)
# see: https://github.com/PragTob/benchee/pull/195#issuecomment-377010006
{_, os} = :os.type()

exclusions =
  if os == :nt do
    [{:performance, true} | exclusions]
  else
    # with our new nanosecond accuracy we can't trigger our super fast function code
    # anymore on Linux/MacOS
    [{:needs_fast_function_repetition, true} | exclusions]
  end

ExUnit.start(exclude: exclusions)
