list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.run(%{time: 3}, %{
  "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten end
})

# tobi@happy ~/github/benchee $ mix run samples/run_old_config.exs
# Erlang/OTP 19 [erts-8.1] [source-4cc2ce3] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]
# Elixir 1.3.4
# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 3.0s
# parallel: 1
# Estimated total run time: 10.0s
#
# Benchmarking flat_map...
# Benchmarking map.flatten...
#
# Name                  ips        average  deviation         median
# map.flatten        1.26 K        0.80 ms    ±15.96%        0.75 ms
# flat_map           0.86 K        1.17 ms     ±4.48%        1.18 ms
#
# Comparison:
# map.flatten        1.26 K
# flat_map           0.86 K - 1.46x slower
