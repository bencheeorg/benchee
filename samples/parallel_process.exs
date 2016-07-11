# When passing a flag parallel with value >1 then multiple processes
# will be handled for benchmarking provided function.

Benchee.run %{parallel: 1, time: 10}, %{"one" => fn -> :timer.sleep(1000) end}
Benchee.run %{parallel: 3, time: 10}, %{"three" => fn -> :timer.sleep(1000) end}
Benchee.run %{parallel: 5, time: 10}, %{"five" => fn -> :timer.sleep(1000) end}

# tobi@happy ~/github/benchee $ mix run samples/parallel_process.exs
# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 10.0s
# parallel: 1
# Estimated total run time: 12.0s
#
# Benchmarking one...
#
# Name           ips        average    deviation         median
# one           1.00   1000994.78μs     (±0.00%)   1000994.00μs
# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 10.0s
# parallel: 3
# Estimated total run time: 12.0s
#
# Benchmarking three...
#
# Name            ips        average    deviation         median
# three          1.00   1000999.00μs     (±0.00%)   1000999.00μs
# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 10.0s
# parallel: 5
# Estimated total run time: 12.0s
#
# Benchmarking five...
#
# Name           ips        average    deviation         median
# five          1.00   1001000.18μs     (±0.00%)   1001000.00μs
