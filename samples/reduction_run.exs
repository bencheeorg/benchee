list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(
  %{
    "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
  },
  time: 0,
  reduction_time: 2
)

# tobi@qiqi:~/github/benchee(docs++)$ mix run samples/reduction_run.exs
# Operating System: Linux
# CPU Information: AMD Ryzen 9 5900X 12-Core Processor
# Number of Available Cores: 24
# Available memory: 31.27 GB
# Elixir 1.13.3
# Erlang 24.2.1

# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 0 ns
# memory time: 0 ns
# reduction time: 2 s
# parallel: 1
# inputs: none specified
# Estimated total run time: 8 s

# Benchmarking flat_map ...
# Benchmarking map.flatten ...

# Reduction count statistics:

# Name        Reduction count
# flat_map            65.01 K
# map.flatten        124.52 K - 1.92x reduction count +59.51 K
