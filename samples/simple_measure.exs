Benchee.init
|> Benchee.benchmark("map", fn -> Enum.map(1..1_000, fn(i) -> i + 1 end) end)
|> Benchee.Statistics.statistics
|> Benchee.Formatters.String.format
|> IO.puts
