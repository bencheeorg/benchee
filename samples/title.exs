list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(
  %{
    "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
  },
  time: 2,
  title: "Comparing map.flatten and flat_map"
)

# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.8.1
# Erlang 21.3.2

# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 2 s
# memory time: 0 ns
# parallel: 1
# inputs: none specified
# Estimated total run time: 8 s

# Benchmarking flat_map...
# Benchmarking map.flatten...

# *** Comparing map.flatten and flat_map ***

# Name                  ips        average  deviation         median         99th %
# flat_map           2.34 K      427.87 μs    ±19.45%      405.68 μs      769.93 μs
# map.flatten        1.25 K      801.46 μs    ±19.65%      751.36 μs     1202.12 μs

# Comparison:
# flat_map           2.34 K
# map.flatten        1.25 K - 1.87x slower +373.59 μs
