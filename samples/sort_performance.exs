list_10k  = 1..10_000 |> Enum.to_list |> Enum.shuffle
list_100k = 1..100_000 |> Enum.to_list |> Enum.shuffle

Benchee.run %{"10k"  => fn -> Enum.sort(list_10k) end,
              "100k" => fn -> Enum.sort(list_100k) end}

# tobi@happy ~/github/benchee $ mix run samples/sort_performance.exs
# Erlang/OTP 19 [erts-8.1] [source-4cc2ce3] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]
# Elixir 1.3.4
# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 5.0s
# parallel: 1
# Estimated total run time: 14.0s
#
# Benchmarking 100k...
# Benchmarking 10k...
#
# Name           ips        average  deviation         median
# 10k         692.27        1.44 ms    ±11.44%        1.39 ms
# 100k         55.82       17.92 ms     ±4.98%       17.78 ms
#
# Comparison:
# 10k         692.27
# 100k         55.82 - 12.40x slower
