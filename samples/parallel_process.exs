# When passing a flag parallel with value >1 then multiple processes
# will be handled for benchmarking provided function.

Benchee.run %{"one" => fn -> :timer.sleep(1000) end}, parallel: 1, time: 10
Benchee.run %{"three" => fn -> :timer.sleep(1000) end}, parallel: 3, time: 10
Benchee.run %{"five" => fn -> :timer.sleep(1000) end}, parallel: 5, time: 10

# tobi@happy ~/github/benchee $ mix run samples/parallel_process.exs
# Erlang/OTP 19 [erts-8.1] [source-4cc2ce3] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]
# Elixir 1.3.4
# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 10.0s
# parallel: 1
# Estimated total run time: 12.0s
#
# Benchmarking one...
#
# Name           ips        average  deviation         median
# one           1.00         1.00 s     ±0.00%         1.00 s
# Erlang/OTP 19 [erts-8.1] [source-4cc2ce3] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]
# Elixir 1.3.4
# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 10.0s
# parallel: 3
# Estimated total run time: 12.0s
#
# Benchmarking three...
#
# Name            ips        average  deviation         median
# three          1.00         1.00 s     ±0.00%         1.00 s
# Erlang/OTP 19 [erts-8.1] [source-4cc2ce3] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]
# Elixir 1.3.4
# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 10.0s
# parallel: 5
# Estimated total run time: 12.0s
#
# Benchmarking five...
#
# Name           ips        average  deviation         median
# five          1.00         1.00 s     ±0.00%         1.00 s
