Benchee.run %{"some very long name that doesn't fit in the space" => fn -> :timer.sleep(100) end}

# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 5.0s
# parallel: 1
# Estimated total run time: 7.0s
#
# Benchmarking some very long name that doesn't fit in the space...
#
# Name                                                        ips        average    deviation         median
# some very long name that doesn't fit in the space          9.90    100994.24μs     (±0.01%)    100994.00μs
