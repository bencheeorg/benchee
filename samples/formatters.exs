list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

format_fun = fn(%{run_times: run_times}) ->
  IO.puts ""
  Enum.each run_times, fn({name, times}) ->
    IO.puts "Benchee recorded #{Enum.count times} run times for #{name}!"
  end
end

Benchee.run(
  %{
    formatters: [
      format_fun,
      &Benchee.Formatters.Console.output/1
    ],
    csv: %{file: "my.csv"}
  },
  %{
    "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten end
  })

# tobi@happy ~/github/benchee $ mix run samples/formatters.exs 
# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 5.0s
# parallel: 1
# Estimated total run time: 14.0s
#
# Benchmarking flat_map...
# Benchmarking map.flatten...
#
# Benchee recorded 4378 run times for flat_map!
# Benchee recorded 6673 run times for map.flatten!
#
# Name                  ips        average    deviation         median
# map.flatten       1336.48       748.23μs    (±11.27%)       752.00μs
# flat_map           876.42      1141.00μs     (±6.66%)      1097.00μs
#
# Comparison:
# map.flatten       1336.48
# flat_map           876.42 - 1.52x slower
