Benchee.run %{"some very long name that doesn't fit in the space" => fn -> :timer.sleep(100) end}

# Erlang/OTP 19 [erts-8.1] [source-4cc2ce3] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]
# Elixir 1.3.4
# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 5.0s
# parallel: 1
# Estimated total run time: 7.0s
#
# Benchmarking some very long name that doesn't fit in the space...
#
# Name                                                        ips        average  deviation         median
# some very long name that doesn't fit in the space          9.90      100.99 ms     ±0.01%      100.99 m
