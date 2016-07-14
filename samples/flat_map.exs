list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.run(%{time: 8}, %{
  ":lists.flatmap" => fn -> :lists.flatmap(map_fun, list) end,
  "flat_map"        => fn -> Enum.flat_map(list, map_fun) end,
  "map |> flatten"  => fn -> list |> Enum.map(map_fun) |> List.flatten end
})
