list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

suite =
  Benchee.run(
    %{
      "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
      "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
    },
    formatters: [{Benchee.Formatters.Console, extended_statistics: true}],
    exclude_outliers: true,
    warmup: 0,
    time: 1
  )

suite.scenarios
|> Enum.map(fn scenario ->
  statistics = scenario.run_time_data.statistics

  {scenario.name, length(statistics.outliers), statistics.lower_outlier_bound,
   statistics.upper_outlier_bound, statistics.outliers}
end)
|> IO.inspect(printable_limit: :infinity, limit: :infinity)
