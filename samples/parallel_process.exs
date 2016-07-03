# When passing a flag parallel with value >1 then multiple processes
# will be handled for benchmarking provided function.

Benchee.run %{parallel: 5, time: 10}, [{"five", fn -> :timer.sleep(1000) end}]

#iex(1)> Benchee.run %{time: 10}, [{"one", fn -> :timer.sleep(1000) end}]
#Benchmarking name: one, parallel: 1, time: 10.0, warmup: 2.0...
#
#Name           ips        average    deviation         median
#one             1.00   1004495.78μs     (±0.15%)   1005146.00μs

#iex(2)> Benchee.run %{parallel: 5, time: 10}, [{"five", fn -> :timer.sleep(1000) end}]
#Benchmarking name: five, parallel: 5, time: 10.0, warmup: 2.0...
#
#Name           ips        average    deviation         median
#five            4.98   1003737.24μs     (±0.10%)   1003672.00μs
