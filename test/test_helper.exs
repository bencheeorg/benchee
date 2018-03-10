otp_release = List.to_integer(:erlang.system_info(:otp_release))
exclusions = if otp_release > 18, do: [], else: [memory_measure: true]

ExUnit.start(exclude: exclusions)
