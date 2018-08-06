list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.run(%{
  "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten end
}, time: 10, formatters: [{Benchee.Formatters.Console, extended_statistics: true}])

# tobi@speedy ~/github/benchee $ mix run samples/run_extended_statistics.exs
# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.5.2
# Erlang 20.0
# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 10 s
# parallel: 1
# inputs: none specified
# Estimated total run time: 24 s
#
#
# Benchmarking flat_map...
# Benchmarking map.flatten...
#
# Name                  ips        average  deviation         median         99th %
# flat_map           2.29 K      435.90 μs     ±8.35%         430 μs      624.68 μs
# map.flatten        1.30 K      766.99 μs    ±24.48%         764 μs        1307 μs
#
# Comparison:
# flat_map           2.29 K
# map.flatten        1.30 K - 1.76x slower
#
# Extended statistics:
#
# Name                minimum        maximum    sample size                     mode
# flat_map             365 μs        1371 μs        22.88 K                   430 μs
# map.flatten          514 μs        1926 μs        13.01 K                   517 μs
