defmodule Escript do
  # is just testdummy
  @moduledoc false
  def main(_args \\ []) do
    list = Enum.to_list(1..10_000)
    map_fun = fn i -> [i, i * i] end

    Benchee.run(
      %{
        "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
        "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
      },
      time: 0.01,
      warmup: 0.005
    )
  end
end
