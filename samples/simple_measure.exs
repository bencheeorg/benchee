Benchee.init
|> Benchee.benchmark("map", fn -> Enum.map(1..1_000, fn(i) -> i + 1 end) end)
|> Benchee.measure
|> Benchee.Statistics.statistics
|> Benchee.Formatters.Console.format
|> IO.puts

# tobi@happy ~/github/benchee $ mix run samples/simple_measure.exs
# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 5.0s
# parallel: 1
# Estimated total run time: 7.0s
#
# Benchmarking map...
#
# Name           ips        average    deviation         median
# map       20294.59        49.27μs     (±7.48%)        49.00μs
