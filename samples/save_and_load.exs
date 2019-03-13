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
  console: [extended_statistics: true]
)

# tobi@speedy ~/github/benchee $ mix run samples/save_and_load.exs
# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.5.2
# Erlang 20.0
# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 5 s
# parallel: 1
# inputs: none specified
# Estimated total run time: 14 s
#
#
# Benchmarking flat_map...
# Benchmarking map.flatten...
#
# Name                  ips        average  deviation         median         99th %
# flat_map           2.26 K      441.63 μs    ±11.67%         432 μs      764.10 μs
# map.flatten        1.18 K      846.59 μs    ±18.85%         804 μs     1311.24 μs
#
# Comparison:
# flat_map           2.26 K
# map.flatten        1.18 K - 1.92x slower
# Suite saved in external term format at save_first-try.benchee
# ----------------------------------------------
# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.5.2
# Erlang 20.0
# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 5 s
# parallel: 1
# inputs: none specified
# Estimated total run time: 28 s
#
#
# Benchmarking flat_map...
# Benchmarking map.flatten...
#
# Name                              ips        average  deviation         median         99th %
# flat_map                       2.28 K      438.24 μs     ±8.96%         432 μs         741 μs
# flat_map (first-try)           2.26 K      441.63 μs    ±11.67%         432 μs      764.10 μs
# map.flatten (first-try)        1.18 K      846.59 μs    ±18.85%         804 μs     1311.24 μs
# map.flatten                    1.18 K      849.42 μs    ±19.62%         800 μs        1359 μs
#
# Comparison:
# flat_map                       2.28 K
# flat_map (first-try)           2.26 K - 1.01x slower
# map.flatten (first-try)        1.18 K - 1.93x slower
# map.flatten                    1.18 K - 1.94x slower
#
# Extended statistics:
#
# Name                            minimum        maximum    sample size                     mode
# flat_map                         367 μs        1508 μs        11.38 K                   432 μs
# flat_map (first-try)             367 μs        1556 μs        11.29 K                   432 μs
# map.flatten (first-try)          529 μs        1774 μs         5.90 K                   792 μs
# map.flatten                      529 μs        1945 μs         5.88 K           792 μs, 793 μs
