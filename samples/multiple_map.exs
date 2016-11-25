# Better define this module in a .ex file and then just refer to the methods
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
# Erlang/OTP 19 [erts-8.1] [source-4cc2ce3] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]
# Elixir 1.3.4
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
# Name                               ips        average  deviation         median
# stdlib map                     65.83 K       15.19 μs    ±15.89%       15.00 μs
# bodyrecusrive map              65.68 K       15.23 μs    ±18.47%       15.00 μs
# map tco no reverse             61.45 K       16.27 μs    ±23.99%       16.00 μs
# map with TCO and reverse       56.81 K       17.60 μs    ±24.37%       17.00 μs
# map with TCO and ++             0.94 K     1063.33 μs     ±6.11%     1041.00 μs
#
# Comparison:
# stdlib map                     65.83 K
# bodyrecusrive map              65.68 K - 1.00x slower
# map tco no reverse             61.45 K - 1.07x slower
# map with TCO and reverse       56.81 K - 1.16x slower
# map with TCO and ++             0.94 K - 70.00x slower
