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

# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.8.1
# Erlang 21.2.7

# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 5 s
# memory time: 2 s
# parallel: 1
# inputs: Bigger, Small
# Estimated total run time: 36 s

# Benchmarking flat_map with input Bigger...
# Benchmarking flat_map with input Small...
# Benchmarking map.flatten with input Bigger...
# Benchmarking map.flatten with input Small...

# ##### With input Bigger #####
# Name                  ips        average  deviation         median         99th %
# flat_map           154.22        6.48 ms    ±12.34%        6.39 ms        8.62 ms
# map.flatten        113.79        8.79 ms    ±15.09%        8.55 ms       12.32 ms

# Comparison:
# flat_map           154.22
# map.flatten        113.79 - 1.36x slower +2.30 ms

# Memory usage statistics:

# Name           Memory usage
# flat_map            6.10 MB
# map.flatten         7.63 MB - 1.25x memory usage +1.53 MB

# **All measurements for memory usage were the same**

# ##### With input Small #####
# Name                  ips        average  deviation         median         99th %
# flat_map          28.27 K       35.37 μs    ±11.25%       34.70 μs       53.44 μs
# map.flatten       18.53 K       53.98 μs    ±12.79%       52.19 μs       90.07 μs

# Comparison:
# flat_map          28.27 K
# map.flatten       18.53 K - 1.53x slower +18.61 μs

# Memory usage statistics:

# Name           Memory usage
# flat_map           62.47 KB
# map.flatten        78.13 KB - 1.25x memory usage +15.66 KB

# **All measurements for memory usage were the same**
