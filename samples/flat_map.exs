list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.run(%{
  ":lists.flatmap" => fn -> :lists.flatmap(map_fun, list) end,
  "flat_map"        => fn -> Enum.flat_map(list, map_fun) end,
  "map |> flatten"  => fn -> list |> Enum.map(map_fun) |> List.flatten end
}, time: 8)

# Erlang/OTP 19 [erts-8.1] [source-4cc2ce3] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]
# Elixir 1.3.4
# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 8.0s
# parallel: 1
# Estimated total run time: 30.0s
#
# Benchmarking :lists.flatmap...
# Benchmarking flat_map...
# Benchmarking map |> flatten...
#
# Name                     ips        average  deviation         median
# :lists.flatmap        2.32 K      431.01 μs    ±10.49%      423.00 μs
# map |> flatten        1.33 K      751.88 μs    ±15.88%      745.00 μs
# flat_map              0.86 K     1161.63 μs    ±10.56%     1154.00 μs
#
# Comparison:
# :lists.flatmap        2.32 K
# map |> flatten        1.33 K - 1.74x slower
# flat_map              0.86 K - 2.70x slower
