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

# tobi@speedy:~/github/benchee(readme-overhaul)$ mix run samples/multiple_inputs.exs
# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.8.1
# Erlang 21.2.7

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
# flat_map           150.81        6.63 ms    ±12.65%        6.57 ms        8.74 ms
# map.flatten        114.05        8.77 ms    ±16.22%        8.42 ms       12.76 ms

# Comparison:
# flat_map           150.81
# map.flatten        114.05 - 1.32x slower +2.14 ms

# ##### With input Medium #####
# Name                  ips        average  deviation         median         99th %
# flat_map           2.28 K      437.80 μs    ±10.72%      425.63 μs      725.09 μs
# map.flatten        1.78 K      561.18 μs     ±5.55%      553.98 μs      675.98 μs

# Comparison:
# flat_map           2.28 K
# map.flatten        1.78 K - 1.28x slower +123.37 μs

# ##### With input Small #####
# Name                  ips        average  deviation         median         99th %
# flat_map          26.31 K       38.01 μs    ±15.47%       36.69 μs       67.08 μs
# map.flatten       18.65 K       53.61 μs    ±11.32%       52.79 μs       70.17 μs

# Comparison:
# flat_map          26.31 K
# map.flatten       18.65 K - 1.41x slower +15.61 μs
