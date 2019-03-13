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
  memory_time: 2
)

# Operating System: macOS
# CPU Information: Intel(R) Core(TM) i5-4260U CPU @ 1.40GHz
# Number of Available Cores: 4
# Available memory: 8 GB
# Elixir 1.6.0
# Erlang 20.2
# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 5 s
# parallel: 1
# inputs: Bigger, Small
# Estimated total run time: 28 s

# Benchmarking flat_map with input Bigger...
# Benchmarking flat_map with input Small...
# Benchmarking map.flatten with input Bigger...
# Benchmarking map.flatten with input Small...

###### With input Bigger #####
# Name                  ips        average  deviation         median         99th %
# flat_map            77.08       12.97 ms    ±15.98%       12.20 ms       18.35 ms
# map.flatten         64.89       15.41 ms    ±20.95%       15.09 ms       34.63 ms

# Comparison:
# flat_map            77.08
# map.flatten         64.89 - 1.19x slower

# Memory usage statistics:

# Name           Memory usage
# flat_map            6.10 MB
# map.flatten         7.63 MB - 1.25x memory usage

# **All measurements for memory usage were the same**

###### With input Small #####
# Name                  ips        average  deviation         median         99th %
# flat_map           6.91 K      144.79 μs   ±106.81%          81 μs         630 μs
# map.flatten        5.65 K      177.08 μs    ±75.42%         120 μs         598 μs

# Comparison:
# flat_map           6.91 K
# map.flatten        5.65 K - 1.22x slower

# Memory usage statistics:

# Name                average  deviation         median         99th %
# flat_map           50.52 KB     ±3.51%       50.62 KB       50.62 KB
# map.flatten        86.37 KB     ±0.00%       86.37 KB       86.37 KB

# Comparison:
# flat_map           50.62 KB
# map.flatten        86.37 KB - 1.71x memory usage
