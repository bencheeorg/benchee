list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.run(%{
  "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten end
}, time: 10)

# tobi@speedy ~/github/benchee $ mix run samples/run.exs
# Elixir 1.4.0
# Erlang 19.1
# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 10.0s
# parallel: 1
# inputs: none specified
# Estimated total run time: 24.0s
#
# Benchmarking flat_map...
# Benchmarking map.flatten...
#
# Name                  ips        average  deviation         median
# flat_map           2.29 K      437.22 μs    ±17.32%      418 μs
# map.flatten        1.28 K      778.50 μs    ±15.92%      767 μs
#
# Comparison:
# flat_map           2.29 K
# map.flatten        1.28 K - 1.78x slower
