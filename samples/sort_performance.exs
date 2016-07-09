list_10k  = 1..10_000 |> Enum.to_list |> Enum.shuffle
list_100k = 1..100_000 |> Enum.to_list |> Enum.shuffle

Benchee.run %{"10k"  => fn -> Enum.sort(list_10k) end,
              "100k" => fn -> Enum.sort(list_100k) end}

# tobi@happy ~/github/benchee $ mix run samples/sort_performance.exs
# Benchmarking 10k...
# Benchmarking 100k...
#
# Name                          ips            average        deviation      median
# 10k                           705.16         1418.11μs      (±10.99%)      1366.00μs
# 100k                          52.74          18960.97μs     (±7.61%)       18233.00μs
#
# Comparison:
# 10k                           705.16
# 100k                          52.74           - 13.37x slower
