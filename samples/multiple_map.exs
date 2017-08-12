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
|> Benchee.system
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

# tobi@speedy ~/github/benchee $ mix run samples/multiple_map.exs
# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 16.372016 GB
# Elixir 1.5.0
# Erlang 20.0
# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 5 s
# parallel: 1
# inputs: none specified
# Estimated total run time: 35 s
#
#
# Benchmarking stdlib map...
# Benchmarking map with TCO and reverse...
# Benchmarking map with TCO and ++...
# Benchmarking bodyrecusrive map...
# Benchmarking map tco no reverse...
#
# Name                               ips        average  deviation         median
# stdlib map                     64.02 K       15.62 μs    ±58.42%          15 μs
# bodyrecusrive map              63.40 K       15.77 μs    ±63.46%          15 μs
# map tco no reverse             57.25 K       17.47 μs    ±53.28%          17 μs
# map with TCO and reverse       52.71 K       18.97 μs    ±57.10%          19 μs
# map with TCO and ++             1.05 K      955.39 μs    ±21.62%         812 μs
#
# Comparison:
# stdlib map                     64.02 K
# bodyrecusrive map              63.40 K - 1.01x slower
# map tco no reverse             57.25 K - 1.12x slower
# map with TCO and reverse       52.71 K - 1.21x slower
# map with TCO and ++             1.05 K - 61.17x slower
