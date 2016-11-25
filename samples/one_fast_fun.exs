# Also way too fast and therefore not super feasible, more a test if
# if benchmarking super fast functions has gotten any better.
Benchee.run(%{"fast" => fn -> 1 + 1 end}, time: 1)

# tobi@happy ~/github/benchee $ mix run samples/one_fast_fun.exs
# Erlang/OTP 19 [erts-8.1] [source-4cc2ce3] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]
# Elixir 1.3.4
# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 1.0s
# parallel: 1
# Estimated total run time: 3.0s
#
# Benchmarking fast...
# Warning: The function you are trying to benchmark is super fast, making measures more unreliable! See: https://github.com/PragTob/benchee/wiki/Benchee-Warnings#fast-execution-warning
#
#
# Name           ips        average  deviation         median
# fast       88.95 M      0.0112 μs    ±14.82%      0.0110 μs
