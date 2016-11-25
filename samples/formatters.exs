list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

format_fun = fn(%{run_times: run_times}) ->
  IO.puts ""
  run_times = Map.get run_times, Benchee.Benchmark.no_input
  Enum.each run_times, fn({name, times}) ->
    IO.puts "Benchee recorded #{Enum.count times} run times for #{name}!"
  end
end

Benchee.run(%{
  "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten end},
  formatters: [
    format_fun,
    &Benchee.Formatters.Console.output/1]
)

# tobi@happy ~/github/benchee $ mix run samples/formatters.exs
# Erlang/OTP 19 [erts-8.1] [source-4cc2ce3] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]
# Elixir 1.3.4
# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 5.0s
# parallel: 1
# Estimated total run time: 14.0s
#
# Benchmarking flat_map...
# Benchmarking map.flatten...
#
# Benchee recorded 4310 run times for flat_map!
# Benchee recorded 6429 run times for map.flatten!
#
# Name                  ips        average  deviation         median
# map.flatten        1.29 K        0.78 ms    ±14.44%        0.75 ms
# flat_map           0.86 K        1.16 ms     ±6.23%        1.17 ms
#
# Comparison:
# map.flatten        1.29 K
# flat_map           0.86 K - 1.49x slower
