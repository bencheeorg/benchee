list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(
  %{
    "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
  },
  time: 10,
  memory_time: 2
)

# tobi@speedy:~/github/benchee(master)$ mix run samples/run.exs
# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.8.1
# Erlang 21.2.7

# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 10 s
# memory time: 2 s
# parallel: 1
# inputs: none specified
# Estimated total run time: 28 s


# Benchmarking flat_map...
# Benchmarking map.flatten...

# Name                  ips        average  deviation         median         99th %
# flat_map           2.36 K      424.38 μs    ±13.24%      411.19 μs      761.59 μs
# map.flatten        1.24 K      806.83 μs    ±16.60%      767.85 μs     1189.10 μs

# Comparison:
# flat_map           2.36 K
# map.flatten        1.24 K - 1.90x slower - +382.45 μs

# Memory usage statistics:

# Name           Memory usage
# flat_map          624.97 KB
# map.flatten       781.25 KB - 1.25x memory usage - +156.28 KB

# **All measurements for memory usage were the same**
