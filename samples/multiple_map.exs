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
# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 5.0s
# parallel: 1
# Estimated total run time: 35.0s
#
# Benchmarking bodyrecusrive map...
# Benchmarking map tco no reverse...
# Benchmarking map with TCO and ++...
# Benchmarking map with TCO and reverse...
# Benchmarking stdlib map...
#
# Name                               ips        average    deviation         median
# stdlib map                    65621.82        15.24μs    (±14.74%)        15.00μs
# bodyrecusrive map             64979.38        15.39μs    (±20.95%)        15.00μs
# map tco no reverse            64727.63        15.45μs    (±12.59%)        15.00μs
# map with TCO and reverse      57646.09        17.35μs    (±24.10%)        17.00μs
# map with TCO and ++             897.18      1114.60μs     (±6.49%)      1086.00μs
#
# Comparison:
# stdlib map                    65621.82
# bodyrecusrive map             64979.38 - 1.01x slower
# map tco no reverse            64727.63 - 1.01x slower
# map with TCO and reverse      57646.09 - 1.14x slower
# map with TCO and ++             897.18 - 73.14x slower
