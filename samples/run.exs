list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.run(%{
  "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten end
}, time: 10, memory_time: 2)

# tobi@speedy:~/github/benchee(master)$ mix run samples/run.exs
# Operating System: Linux"
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.6.4
# Erlang 20.3
#
# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 10 s
# memory time: 2 s
# parallel: 1
# inputs: none specified
# Estimated total run time: 28 s
#
#
# Benchmarking flat_map...
# Benchmarking map.flatten...
#
# Name                  ips        average  deviation         median         99th %
# flat_map           2.31 K      433.25 μs     ±8.64%         428 μs         729 μs
# map.flatten        1.22 K      822.22 μs    ±16.43%         787 μs        1203 μs
#
# Comparison:
# flat_map           2.31 K
# map.flatten        1.22 K - 1.90x slower
#
# Memory usage statistics:
#
# Name           Memory usage
# flat_map          625.54 KB
# map.flatten       781.85 KB - 1.25x memory usage
#
# **All measurements for memory usage were the same**

