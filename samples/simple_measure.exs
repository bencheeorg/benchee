Benchee.init
|> Benchee.benchmark("map", fn -> Enum.map(1..1_000, fn(i) -> i + 1 end) end)
|> Benchee.measure
|> Benchee.Statistics.statistics
|> Benchee.Formatters.Console.format
|> IO.puts

# tobi@happy ~/github/benchee $ mix run samples/simple_measure.exs
# Benchmarking map...
#
# Name                          ips            average        deviation      median
# map                           18197.42       54.95μs        (±11.32%)      54.00μs
