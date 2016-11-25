list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.init(time: 3)
|> Benchee.benchmark("flat_map", fn -> Enum.flat_map(list, map_fun) end)
|> Benchee.benchmark("map.flatten",
                     fn -> list |> Enum.map(map_fun) |> List.flatten end)
|> Benchee.measure
|> Benchee.statistics
|> Benchee.Formatters.Console.format
|> IO.puts

# tobi@happy ~/github/benchee $ mix run samples/run_expanded.exs
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
# map.flatten        1.27 K        0.79 ms    ±14.20%        0.76 ms
# flat_map           0.86 K        1.16 ms     ±5.84%        1.18 ms
#
# Comparison:
# map.flatten        1.27 K
# flat_map           0.86 K - 1.47x slower
