defmodule MyMap do

  def map(list, function) do
    Enum.reverse _map([], list, function)
  end

  defp _map(acc, [head | tail], function) do
    _map([function.(head) | acc], tail, function)
  end

  defp _map(acc, [], _function) do
    acc
  end

  def map2(acc \\ [], list, function)

  def map2(acc, [head | tail], function) do
    map2(acc ++ [function.(head)], tail, function)
  end

  def map2(acc, [], _function) do
    acc
  end

  def map3([], _func), do: []

  def map3([head | tail], func) do
    [func.(head) | map(tail, func)]
  end
end


list = Enum.to_list(1..1_000)
map_function = fn(i) -> i + 1 end
Benchee.init(%{time: 3})
|> Benchee.benchmark("stdlib map", fn -> Enum.map(list, map_function) end)
|> Benchee.benchmark("map with TCO and reverse", fn -> MyMap.map(list, map_function) end)
|> Benchee.benchmark("map with ++ and TCO", fn -> MyMap.map2(list, map_function) end)
|> Benchee.benchmark("simple map without TCO", fn -> MyMap.map3(list, map_function) end)
|> Benchee.Statistics.statistics
|> Benchee.Formatters.String.format
|> IO.puts
