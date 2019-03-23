list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(
  %{
    "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
  },
  time: 10,
  memory_time: 2
)

# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.8.1
# Erlang 21.2.7

# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 10 s
# memory time: 2 s
# parallel: 1
# inputs: none specified
# Estimated total run time: 28 s

# Benchmarking flat_map...
# Benchmarking map.flatten...

# Name                  ips        average  deviation         median         99th %
# flat_map           2.34 K      426.84 μs     ±9.88%      418.72 μs      720.20 μs
# map.flatten        1.18 K      844.08 μs    ±19.73%      778.10 μs     1314.87 μs

# Comparison:
# flat_map           2.34 K
# map.flatten        1.18 K - 1.98x slower +417.24 μs

# Memory usage statistics:

# Name           Memory usage
# flat_map          624.97 KB
# map.flatten       781.25 KB - 1.25x memory usage +156.28 KB

# **All measurements for memory usage were the same**
