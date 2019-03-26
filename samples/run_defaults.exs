list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(%{
  "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
})

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
# inputs: none specified
# Estimated total run time: 14 s

# Benchmarking flat_map...
# Benchmarking map.flatten...

# Name                  ips        average  deviation         median         99th %
# flat_map           2.36 K      423.20 μs    ±16.84%      405.89 μs      771.85 μs
# map.flatten        1.26 K      795.99 μs    ±20.06%      745.23 μs     1260.17 μs

# Comparison:
# flat_map           2.36 K
# map.flatten        1.26 K - 1.88x slower +372.79 μs
