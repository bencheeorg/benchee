# This is the old data structure (pre 0.3.0), but it still works!

list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.run(%{time: 3},
             [{"flat_map", fn -> Enum.flat_map(list, map_fun) end},
              {"map.flatten",
              fn -> list |> Enum.map(map_fun) |> List.flatten end}])

# tobi@happy ~/github/benchee $ mix run samples/run_legacy_format.exs
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
# map.flatten       1309.73       763.52μs    (±12.04%)       752.00μs
# flat_map           865.17      1155.85μs    (±11.39%)      1187.00μs
#
# Comparison:
# map.flatten       1309.73
# flat_map           865.17 - 1.51x slower
