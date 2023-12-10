list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(
  %{
    "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
  },
  # report will give us the output
  formatters: [],
  time: 5,
  save: [path: "save.benchee", tag: "save-me"]
)

IO.puts("----------------------------------------------")

Benchee.report(
  load: "save.benchee",
  formatters: [{Benchee.Formatters.Console, extended_statistics: true}]
)

# Operating System: Linux
# CPU Information: AMD Ryzen 9 5900X 12-Core Processor
# Number of Available Cores: 24
# Available memory: 31.25 GB
# Elixir 1.16.0-rc.0
# Erlang 26.1.2
# JIT enabled: true

# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 5 s
# memory time: 0 ns
# reduction time: 0 ns
# parallel: 1
# inputs: none specified
# Estimated total run time: 14 s

# Benchmarking flat_map ...
# Benchmarking map.flatten ...
# Calculating statistics...
# Formatting results...
# Suite saved in external term format at save.benchee
# ----------------------------------------------
# Formatting results...

# Name                            ips        average  deviation         median         99th %
# flat_map (save-me)           3.69 K      270.69 μs    ±21.13%      259.71 μs      703.98 μs
# map.flatten (save-me)        1.88 K      530.50 μs    ±45.74%      410.19 μs     1227.46 μs

# Comparison:
# flat_map (save-me)           3.69 K
# map.flatten (save-me)        1.88 K - 1.96x slower +259.82 μs

# Extended statistics:

# Name                          minimum        maximum    sample size                     mode
# flat_map (save-me)          215.30 μs     1066.77 μs        18.44 K                257.25 μs
# map.flatten (save-me)       203.19 μs     1522.54 μs         9.41 K406.65 μs, 406.35 μs, 377
