list_10k  = 1..10_000 |> Enum.to_list |> Enum.shuffle
list_100k = 1..100_000 |> Enum.to_list |> Enum.shuffle

Benchee.run %{"10k"  => fn -> Enum.sort(list_10k) end,
              "100k" => fn -> Enum.sort(list_100k) end}

# tobi@happy ~/github/benchee $ mix run samples/sort_performance.exs
# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 5.0s
# parallel: 1
# Estimated total run time: 14.0s
#
# Benchmarking 100k...
# Benchmarking 10k...
#
# Name           ips        average    deviation         median
# 10k         742.67      1346.50μs     (±5.44%)      1366.00μs
# 100k         52.11     19190.23μs    (±18.45%)     17519.00μs
#
# Comparison:
# 10k         742.67
# 100k         52.11 - 14.25x slower
#
