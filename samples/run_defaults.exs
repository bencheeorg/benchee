list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(%{
  "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
})

# tobi@speedy:~/github/benchee(readme-overhaul)$ mix run samples/run_defaults.exs
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
# inputs: none specified
# Estimated total run time: 14 s

# Benchmarking flat_map...
# Benchmarking map.flatten...

# Name                  ips        average  deviation         median         99th %
# flat_map           2.34 K      427.78 μs    ±16.02%      406.29 μs      743.01 μs
# map.flatten        1.22 K      820.87 μs    ±19.29%      772.61 μs     1286.35 μs

# Comparison:
# flat_map           2.34 K
# map.flatten        1.22 K - 1.92x slower +393.09 μs
