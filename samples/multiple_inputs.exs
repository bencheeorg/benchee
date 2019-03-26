map_fun = fn i -> [i, i * i] end

Benchee.run(
  %{
    "flat_map" => fn input -> Enum.flat_map(input, map_fun) end,
    "map.flatten" => fn input -> input |> Enum.map(map_fun) |> List.flatten() end
  },
  inputs: %{
    "Small" => Enum.to_list(1..1_000),
    "Medium" => Enum.to_list(1..10_000),
    "Bigger" => Enum.to_list(1..100_000)
  }
)

# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.8.1
# Erlang 21.3.2

# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 5 s
# memory time: 0 ns
# parallel: 1
# inputs: Bigger, Medium, Small
# Estimated total run time: 42 s

# Benchmarking flat_map with input Bigger...
# Benchmarking flat_map with input Medium...
# Benchmarking flat_map with input Small...
# Benchmarking map.flatten with input Bigger...
# Benchmarking map.flatten with input Medium...
# Benchmarking map.flatten with input Small...

# ##### With input Bigger #####
# Name                  ips        average  deviation         median         99th %
# flat_map           148.45        6.74 ms    ±16.22%        6.47 ms       10.14 ms
# map.flatten        111.47        8.97 ms    ±19.02%        8.61 ms       14.02 ms

# Comparison:
# flat_map           148.45
# map.flatten        111.47 - 1.33x slower +2.23 ms

# ##### With input Medium #####
# Name                  ips        average  deviation         median         99th %
# flat_map           2.34 K      426.50 μs    ±17.11%      405.51 μs      817.00 μs
# map.flatten        1.79 K      558.80 μs    ±19.87%      523.28 μs     1064.58 μs

# Comparison:
# flat_map           2.34 K
# map.flatten        1.79 K - 1.31x slower +132.31 μs

# ##### With input Small #####
# Name                  ips        average  deviation         median         99th %
# flat_map          24.42 K       40.95 μs    ±31.34%       34.88 μs       77.32 μs
# map.flatten       18.06 K       55.36 μs    ±26.46%       49.52 μs      105.45 μs

# Comparison:
# flat_map          24.42 K
# map.flatten       18.06 K - 1.35x slower +14.41 μs
