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
# flat_map           2.40 K      417.31 μs    ±12.98%      406.10 μs      728.39 μs
# map.flatten        1.27 K      787.55 μs    ±18.48%      743.45 μs     1172.37 μs

# Comparison:
# flat_map           2.40 K
# map.flatten        1.27 K - 1.89x slower +370.24 μs
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
# flat_map                       2.42 K      414.01 μs    ±11.90%      406.17 μs      712.99 μs
# flat_map (first-try)           2.40 K      417.31 μs    ±12.98%      406.10 μs      728.39 μs
# map.flatten                    1.27 K      784.75 μs    ±18.42%      743.95 μs     1190.36 μs
# map.flatten (first-try)        1.27 K      787.55 μs    ±18.48%      743.45 μs     1172.37 μs

# Comparison:
# flat_map                       2.42 K
# flat_map (first-try)           2.40 K - 1.01x slower +3.30 μs
# map.flatten                    1.27 K - 1.90x slower +370.74 μs
# map.flatten (first-try)        1.27 K - 1.90x slower +373.54 μs

# Extended statistics:

# Name                            minimum        maximum    sample size                     mode
# flat_map                      345.33 μs     1180.66 μs        12.05 K                405.29 μs
# flat_map (first-try)          345.32 μs     1205.74 μs        11.95 K     405.98 μs, 406.09 μs
# map.flatten                   494.22 μs     1811.82 μs         6.36 K                738.26 μs
# map.flatten (first-try)       493.95 μs     1882.94 μs         6.34 K                740.59 μs
