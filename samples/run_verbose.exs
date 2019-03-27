list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

[time: 3]
|> Benchee.init()
|> Benchee.system()
|> Benchee.benchmark("flat_map", fn -> Enum.flat_map(list, map_fun) end)
|> Benchee.benchmark(
  "map.flatten",
  fn -> list |> Enum.map(map_fun) |> List.flatten() end
)
|> Benchee.collect()
|> Benchee.statistics()
|> Benchee.relative_statistics()
|> Benchee.Formatter.output(Benchee.Formatters.Console)

# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.8.1
# Erlang 21.2.7

# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 3 s
# memory time: 0 ns
# parallel: 1
# inputs: none specified
# Estimated total run time: 10 s

# Benchmarking flat_map...
# Benchmarking map.flatten...

# Name                  ips        average  deviation         median         99th %
# flat_map           2.32 K      430.44 μs    ±16.15%      411.38 μs      732.80 μs
# map.flatten        1.18 K      846.04 μs    ±20.56%      779.01 μs     1237.69 μs

# Comparison:
# flat_map           2.32 K
# map.flatten        1.18 K - 1.97x slower +415.60 μs
