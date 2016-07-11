list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.init(%{time: 3})
|> Benchee.benchmark("flat_map", fn -> Enum.flat_map(list, map_fun) end)
|> Benchee.benchmark("map.flatten",
                     fn -> list |> Enum.map(map_fun) |> List.flatten end)
|> Benchee.measure
|> Benchee.statistics
|> Benchee.Formatters.Console.format
|> IO.puts

# tobi@happy ~/github/benchee $ mix run samples/run_expanded.exs
# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 3.0s
# parallel: 1
# Estimated total run time: 10.0s
#
# Benchmarking flat_map...
# Benchmarking map.flatten...
#
# Name                  ips        average    deviation         median
# map.flatten       1248.24       801.13μs    (±14.03%)       776.00μs
# flat_map           863.27      1158.38μs     (±7.53%)      1205.00μs
#
# Comparison:
# map.flatten       1248.24
# flat_map           863.27 - 1.45x slower
