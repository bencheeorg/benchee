list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.run(%{
  inputs: %{
    "Small" => Enum.to_list(1..1000),
    "Bigger" => Enum.to_list(1..100_000)
    }
  },
  %{
  "flat_map"    => fn(input) -> Enum.flat_map(input, map_fun) end,
  "map.flatten" => fn(input) -> input |> Enum.map(map_fun) |> List.flatten end
})
