map_fun = fn i -> [i, i * i] end

Benchee.run(
  %{
    "flat_map" => fn input ->
      if rem(Enum.random(1..5), 2) == 0 do
        _ = Enum.random(1..10) + Enum.random(1..10)
        Enum.flat_map(input, map_fun)
      else
        Enum.flat_map(input, map_fun)
      end
    end,
    "map.flatten" => fn input ->
      if rem(Enum.random(1..5), 2) == 0 do
        _ = Enum.random(1..10) + Enum.random(1..10)
        input |> Enum.map(map_fun) |> List.flatten()
      else
        input |> Enum.map(map_fun) |> List.flatten()
      end
    end
  },
  inputs: %{
    "Small" => Enum.to_list(1..10),
    "Bigger" => Enum.to_list(1..100)
  },
  time: 0.1,
  warmup: 0.1,
  reduction_time: 0.1
)
