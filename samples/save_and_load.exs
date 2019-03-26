list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(
  %{
    "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
  },
  time: 5,
  save: [path: "save.benchee", tag: "first-try"]
)

IO.puts("----------------------------------------------")

Benchee.run(
  %{
    "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
  },
  time: 5,
  load: "save.benchee",
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
# time: 5 s
# memory time: 0 ns
# parallel: 1
# inputs: none specified
# Estimated total run time: 14 s

# Benchmarking flat_map...
# Benchmarking map.flatten...

# Name                  ips        average  deviation         median         99th %
# flat_map           2.39 K      417.60 μs    ±13.45%      405.57 μs      723.41 μs
# map.flatten        1.26 K      796.12 μs    ±19.81%      742.68 μs     1154.47 μs

# Comparison:
# flat_map           2.39 K
# map.flatten        1.26 K - 1.91x slower +378.52 μs
# Suite saved in external term format at save.benchee
# ----------------------------------------------
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

# Name                              ips        average  deviation         median         99th %
# flat_map                       2.41 K      415.72 μs    ±13.10%      405.28 μs      724.05 μs
# map.flatten                    1.29 K      777.77 μs    ±17.73%      743.63 μs     1163.84 μs
# flat_map (first-try)           2.39 K      417.60 μs    ±13.45%      405.57 μs      723.41 μs
# map.flatten (first-try)        1.26 K      796.12 μs    ±19.81%      742.68 μs     1154.47 μs

# Comparison:
# flat_map                       2.41 K
# map.flatten                    1.29 K - 1.87x slower +362.05 μs
# flat_map (first-try)           2.39 K map.flatten (first-try)        1.26 K - 1.91x slower +378.52 μs

# Extended statistics:

# Name                            minimum        maximum    sample size                     mode
# flat_map                      345.18 μs     1195.24 μs        12.00 K     405.28 μs, 405.28 μs
# map.flatten                   494.08 μs     1479.42 μs         6.42 K                739.22 μs
# flat_map (first-try)          345.21 μs     1273.69 μs        11.94 K     405.52 μs, 405.46 μs
# map.flatten (first-try)       493.44 μs     1614.85 μs         6.27 K                741.30 μs
