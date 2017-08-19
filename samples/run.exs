list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.run(%{
  "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten end
}, time: 10)

# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 16.37 GB
# Elixir 1.5.0
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
# Name                  ips        average  deviation         median
# flat_map           2.26 K      442.67 μs    ±12.59%         429 μs
# map.flatten        1.34 K      744.88 μs    ±22.99%         702 μs
#
# Comparison:
# flat_map           2.26 K
# map.flatten        1.34 K - 1.68x slower
