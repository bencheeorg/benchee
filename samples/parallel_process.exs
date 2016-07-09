# When passing a flag parallel with value >1 then multiple processes
# will be handled for benchmarking provided function.

Benchee.run %{parallel: 1, time: 10}, %{"one" => fn -> :timer.sleep(1000) end}
Benchee.run %{parallel: 3, time: 10}, %{"three" => fn -> :timer.sleep(1000) end}
Benchee.run %{parallel: 5, time: 10}, %{"five" => fn -> :timer.sleep(1000) end}

# tobi@happy ~/github/benchee $ mix run samples/parallel_process.exs
# Benchmarking one...
#
# Name           ips        average    deviation         median
# one           1.00   1000991.78μs     (±0.00%)   1000994.00μs
# Benchmarking three...
#
# Name            ips        average    deviation         median
# three          1.00   1000998.63μs     (±0.00%)   1000998.00μs
# Benchmarking five...
#
# Name           ips        average    deviation         median
# five          1.00   1000996.24μs     (±0.00%)   1000996.00μs
