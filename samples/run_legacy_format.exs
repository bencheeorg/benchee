list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.run(%{time: 3},
             [{"flat_map", fn -> Enum.flat_map(list, map_fun) end},
              {"map.flatten",
              fn -> list |> Enum.map(map_fun) |> List.flatten end}])

# tobi@happy ~/github/benchee $ mix run samples/run.exs
# Benchmarking flat_map...
# Benchmarking map.flatten...
#
# Name                          ips            average        deviation      median
# map.flatten                   1283.12        779.35μs       (±16.34%)      748.00μs
# flat_map                      882.38         1133.30μs      (±6.87%)       1158.00μs
#
# Comparison:
# map.flatten                   1283.12
# flat_map                      882.38          - 1.45x slower
