defmodule MyMap do

  def map_tco(list, function) do
    Enum.reverse _map_tco([], list, function)
  end

  defp _map_tco(acc, [head | tail], function) do
    _map_tco([function.(head) | acc], tail, function)
  end

  defp _map_tco(acc, [], _function) do
    acc
  end

  def map_tco_concat(acc \\ [], list, function)

  def map_tco_concat(acc, [head | tail], function) do
    map_tco_concat(acc ++ [function.(head)], tail, function)
  end

  def map_tco_concat(acc, [], _function) do
    acc
  end

  def map_body([], _func), do: []

  def map_body([head | tail], func) do
    [func.(head) | map_body(tail, func)]
  end

  def map_tco_no_reverse(list, function) do
    _map_tco([], list, function)
  end
end


list = Enum.to_list(1..1_000)
map_function = fn(i) -> i + 1 end
Benchee.init
|> Benchee.benchmark("stdlib map", fn -> Enum.map(list, map_function) end)
|> Benchee.benchmark("map with TCO and reverse",
                     fn -> MyMap.map_tco(list, map_function) end)
|> Benchee.benchmark("map with TCO and ++",
                     fn -> MyMap.map_tco_concat(list, map_function) end)
|> Benchee.benchmark("bodyrecusrive map",
                     fn -> MyMap.map_body(list, map_function) end)
|> Benchee.benchmark("map tco no reverse",
                     fn -> MyMap.map_tco_no_reverse(list, map_function) end)
|> Benchee.measure
|> Benchee.Statistics.statistics
|> Benchee.Formatters.Console.format
|> IO.puts


# tobi@happy ~/github/benchee $ mix run samples/multiple_map.exs
# Benchmarking stdlib map...
# Benchmarking map with TCO and reverse...
# Benchmarking map with TCO and ++...
# Benchmarking bodyrecusrive map...
# Benchmarking map tco no reverse...
#
# Name                          ips            average        deviation      median
# bodyrecusrive map             65854.74       15.18μs        (±31.83%)      15.00μs
# stdlib map                    65594.56       15.25μs        (±30.44%)      15.00μs
# map tco no reverse            58534.15       17.08μs        (±39.71%)      17.00μs
# map with TCO and reverse      55066.15       18.16μs        (±39.89%)      18.00μs
# map with TCO and ++           739.36         1352.52μs      (±2.60%)       1351.00μs
#
# Comparison:
# bodyrecusrive map             65854.74
# stdlib map                    65594.56        - 1.00x slower
# map tco no reverse            58534.15        - 1.13x slower
# map with TCO and reverse      55066.15        - 1.20x slower
# map with TCO and ++           739.36          - 89.07x slower
