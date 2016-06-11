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
# Benchmarking flat_map...
# Benchmarking map.flatten...
#
# Name                          ips            average        deviation      median
# map.flatten                   1306.15        765.61μs       (±13.86%)      749.00μs
# flat_map                      903.33         1107.01μs      (±6.88%)       1137.00μs
#
# Comparison:
# map.flatten                   1306.15
# flat_map                      903.33          - 1.45x slower
