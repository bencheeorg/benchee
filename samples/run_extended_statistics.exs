list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(
  %{
    "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
  },
  time: 10,
  formatters: [{Benchee.Formatters.Console, extended_statistics: true}]
)

# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.8.1
# Erlang 21.3.2

# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 10 s
# memory time: 0 ns
# parallel: 1
# inputs: none specified
# Estimated total run time: 24 s

# Benchmarking flat_map...
# Benchmarking map.flatten...

# Name                  ips        average  deviation         median         99th %
# flat_map           2.37 K      421.74 μs    ±14.17%      406.44 μs      758.14 μs
# map.flatten        1.24 K      807.37 μs    ±20.22%      747.94 μs     1311.65 μs

# Comparison:
# flat_map           2.37 K
# map.flatten        1.24 K - 1.91x slower +385.64 μs

# Extended statistics:

# Name                minimum        maximum    sample size                     mode
# flat_map          345.15 μs     1182.74 μs        23.64 K                406.28 μs
# map.flatten       492.78 μs     1925.29 μs        12.36 K741.79 μs, 739.21 μs, 738
