list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.run(%{time: 3}, %{
  "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten end
})

# tobi@happy ~/github/benchee $ mix run samples/run.exs
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
# map.flatten       1231.39       812.09μs    (±12.24%)       805.00μs
# flat_map           863.08      1158.64μs     (±6.14%)      1189.00μs
#
# Comparison:
# map.flatten       1231.39
# flat_map           863.08 - 1.43x slower
