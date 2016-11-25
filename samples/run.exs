list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.run(%{
  "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten end
}, time: 3)

# tobi@happy ~/github/benchee $ mix run samples/run.exs
# Erlang/OTP 19 [erts-8.1] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]
# Elixir 1.3.4
# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 3.0s
# parallel: 1
# inputs: none specified
# Estimated total run time: 10.0s
#
# Benchmarking flat_map...
# Benchmarking map.flatten...
#
# Name                  ips        average  deviation         median
# map.flatten        1.27 K        0.79 ms    ±15.34%        0.76 ms
# flat_map           0.85 K        1.18 ms     ±6.00%        1.23 ms
#
# Comparison:
# map.flatten        1.27 K
# flat_map           0.85 K - 1.49x slower
