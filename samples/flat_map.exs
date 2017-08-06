list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.run(%{
  ":lists.flatmap" => fn -> :lists.flatmap(map_fun, list) end,
  "flat_map"        => fn -> Enum.flat_map(list, map_fun) end,
  "map |> flatten"  => fn -> list |> Enum.map(map_fun) |> List.flatten end
}, time: 8)

# tobi@speedy ~/github/benchee $ mix run samples/flat_map.exs
# Compiling 12 files (.ex)
# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 16.372016 GB
# Elixir 1.5.0
# Erlang 20.0
# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 8 s
# parallel: 1
# inputs: none specified
# Estimated total run time: 30 s
#
#
# Benchmarking :lists.flatmap...
# Benchmarking flat_map...
# Benchmarking map |> flatten...
#
# Name                     ips        average  deviation         median
# flat_map              2.31 K      433.50 μs     ±6.96%         428 μs
# :lists.flatmap        2.14 K      466.61 μs     ±7.43%         461 μs
# map |> flatten        1.28 K      780.27 μs    ±20.31%         780 μs
#
# Comparison:
# flat_map              2.31 K
# :lists.flatmap        2.14 K - 1.08x slower
# map |> flatten        1.28 K - 1.80x slower
