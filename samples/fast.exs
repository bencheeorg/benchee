list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(
  %{
    "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
  },
  warmup: 0.1,
  time: 0.3,
  memory_time: 0.3
)

# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.8.1
# Erlang 21.3.2

# Benchmark suite executing with the following configuration:
# warmup: 100 ms
# time: 300 ms
# memory time: 300 ms
# parallel: 1
# inputs: none specified
# Estimated total run time: 1.40 s

# Benchmarking flat_map...
# Benchmarking map.flatten...

# Name                  ips        average  deviation         median         99th %
# flat_map           1.95 K      514.08 μs    ±29.68%      475.22 μs      754.17 μs
# map.flatten        1.22 K      819.85 μs    ±21.26%      769.04 μs     1469.22 μs

# Comparison:
# flat_map           1.95 K
# map.flatten        1.22 K - 1.59x slower +305.77 μs

# Memory usage statistics:

# Name           Memory usage
# flat_map          624.97 KB
# map.flatten       781.25 KB - 1.25x memory usage +156.28 KB

# **All measurements for memory usage were the same**
