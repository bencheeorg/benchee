list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.run(%{time: 3, parallel: 2}, %{
  "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten end
})


# The following benchmarks are from a 4-core system with HT, while on a normal
# work load (music, browser, editor, gui etc.) which is not the ideal
# benchmarking environment ;)
#
# The slight performancedegredation with parallel: 2 is expected (like most CPUs
# mine has a speed boost when only one CPU is occupied). As parallel processes
# grow then performance degrades because they have to contend with everything
# that is running. Therefore, be aware of the impact running benchmarks in
# parallel has on the results.
#
# The original use case that introduced this was more of a stress test of
# a system.
#
# > I needed to benchmark integration tests for a telephony system we wrote -
# > with this system the tests actually interfere with each other (they're using
# > an Ecto repo) and I wanted to see how far I could push the system as a
# > whole. Making this small change to Benchee worked perfectly for what I
# > needed :)
#
# tobi@happy ~/github/benchee $ mix run samples/run.exs # parallel 1
# Benchmarking flat_map...
# Benchmarking map.flatten...
#
# Name                  ips        average    deviation         median
# map.flatten       1276.37       783.47μs    (±12.28%)       759.00μs
# flat_map           878.60      1138.17μs     (±6.82%)      1185.00μs
#
# Comparison:
# map.flatten       1276.37
# flat_map           878.60 - 1.45x slower
# tobi@happy ~/github/benchee $ mix run samples/run_parallel.exs # parallel 2
# Benchmarking flat_map...
# Benchmarking map.flatten...
#
# Name                  ips        average    deviation         median
# map.flatten       1230.53       812.66μs    (±19.86%)       761.00μs
# flat_map           713.82      1400.92μs     (±5.63%)      1416.00μs
#
# Comparison:
# map.flatten       1230.53
# flat_map           713.82 - 1.72x slower
# tobi@happy ~/github/benchee $ mix run samples/run_parallel.exs # parallel 3
# Benchmarking flat_map...
# Benchmarking map.flatten...
#
# Name                  ips        average    deviation         median
# map.flatten       1012.77       987.39μs    (±29.53%)       913.00μs
# flat_map           513.44      1947.63μs     (±6.91%)      1943.50μs
#
# Comparison:
# map.flatten       1012.77
# flat_map           513.44 - 1.97x slower
# tobi@happy ~/github/benchee $ mix run samples/run_parallel.exs # parallel 4
# Benchmarking flat_map...
# Benchmarking map.flatten...
#
# Name                  ips        average    deviation         median
# map.flatten        954.88      1047.25μs    (±34.02%)       957.00μs
# flat_map           452.38      2210.55μs    (±21.05%)      1914.00μs
#
# Comparison:
# map.flatten        954.88
# flat_map           452.38 - 2.11x slower
# tobi@happy ~/github/benchee $ mix run samples/run_parallel.exs # parallel 12
# Benchmarking flat_map...
# Benchmarking map.flatten...
#
# Name                  ips        average    deviation         median
# map.flatten        296.63      3371.18μs    (±57.60%)      2827.00μs
# flat_map           186.96      5348.74μs    (±42.14%)      5769.50μs
#
# Comparison:
# map.flatten        296.63
# flat_map           186.96 - 1.59x slower
