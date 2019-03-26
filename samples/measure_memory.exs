map_fun = fn i -> [i, i * i] end

Benchee.run(
  %{
    "flat_map" => fn input -> Enum.flat_map(input, map_fun) end,
    "map.flatten" => fn input -> input |> Enum.map(map_fun) |> List.flatten() end
  },
  inputs: %{
    "Small" => Enum.to_list(1..1000),
    "Bigger" => Enum.to_list(1..100_000)
  },
  time: 0,
  warmup: 0,
  memory_time: 2
)

# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.8.1
# Erlang 21.3.2

# Benchmark suite executing with the following configuration:
# warmup: 0 ns
# time: 0 ns
# memory time: 2 s
# parallel: 1
# inputs: Bigger, Small
# Estimated total run time: 8 s

# Benchmarking flat_map with input Bigger...
# Benchmarking flat_map with input Small...
# Benchmarking map.flatten with input Bigger...
# Benchmarking map.flatten with input Small...

# ##### With input Bigger #####
# Memory usage statistics:

# Name           Memory usage
# flat_map            6.10 MB
# map.flatten         7.63 MB - 1.25x memory usage +1.53 MB

# **All measurements for memory usage were the same**

# ##### With input Small #####
# Memory usage statistics:

# Name           Memory usage
# flat_map           62.47 KB
# map.flatten        78.13 KB - 1.25x memory usage +15.66 KB

# **All measurements for memory usage were the same**
