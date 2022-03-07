list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(
  %{
    "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
  },
  warmup: 1,
  time: 5,
  memory_time: 2,
  reduction_time: 2
)

# tobi@qiqi:~/github/benchee(docs++)$ mix run samples/run_all.exs
# Operating System: Linux
# CPU Information: AMD Ryzen 9 5900X 12-Core Processor
# Number of Available Cores: 24
# Available memory: 31.27 GB
# Elixir 1.13.3
# Erlang 24.2.1

# Benchmark suite executing with the following configuration:
# warmup: 1 s
# time: 5 s
# memory time: 2 s
# reduction time: 2 s
# parallel: 1
# inputs: none specified
# Estimated total run time: 20 s

# Benchmarking flat_map ...
# Benchmarking map.flatten ...

# Name                  ips        average  deviation         median         99th %
# flat_map           3.61 K      276.99 μs    ±10.39%      273.61 μs      490.68 μs
# map.flatten        2.25 K      444.22 μs    ±21.30%      410.09 μs      703.06 μs

# Comparison:
# flat_map           3.61 K
# map.flatten        2.25 K - 1.60x slower +167.22 μs

# Memory usage statistics:

# Name           Memory usage
# flat_map             625 KB
# map.flatten       781.25 KB - 1.25x memory usage +156.25 KB

# **All measurements for memory usage were the same**

# Reduction count statistics:

# Name        Reduction count
# flat_map            65.01 K
# map.flatten        124.52 K - 1.92x reduction count +59.51 K

# **All measurements for reduction count were the same**
