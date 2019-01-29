list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

format_fun = fn(%{scenarios: scenarios}) ->
  IO.puts ""
  Enum.each scenarios, fn(scenario) ->
    sample_size = scenario.run_time_data.statistics.sample_size
    IO.puts "Benchee recorded #{sample_size} run times for #{scenario.job_name}!"
  end
end

Benchee.run(%{
  "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten end},
  formatters: [
    format_fun,
    Benchee.Formatters.Console,
    {Benchee.Formatters.Console, extended_statistics: true}
  ]
)

# tobi@speedy:~/github/benchee(formatter-options-closer)$ mix run samples/formatters.exs
# Operating System: Linux"
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.7.1
# Erlang 21.0

# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 5 s
# memory time: 0 ns
# parallel: 1
# inputs: none specified
# Estimated total run time: 14 s


# Benchmarking flat_map...
# Benchmarking map.flatten...

# Name                  ips        average  deviation         median         99th %
# flat_map           2.27 K      441.13 μs    ±13.46%      428.82 μs      754.50 μs
# map.flatten        1.17 K      851.99 μs    ±20.39%      786.52 μs     1284.90 μs

# Comparison:
# flat_map           2.27 K
# map.flatten        1.17 K - 1.93x slower

# Name                  ips        average  deviation         median         99th %
# flat_map           2.27 K      441.13 μs    ±13.46%      428.82 μs      754.50 μs
# map.flatten        1.17 K      851.99 μs    ±20.39%      786.52 μs     1284.90 μs

# Comparison:
# flat_map           2.27 K
# map.flatten        1.17 K - 1.93x slower

# Extended statistics:

# Name                minimum        maximum    sample size                     mode
# flat_map          367.55 μs     1259.94 μs        11.31 K     428.79 μs, 428.54 μs
# map.flatten       533.85 μs     1786.02 μs         5.86 K777.58 μs, 778.82 μs, 780

# Benchee recorded 11307 run times for flat_map!
# Benchee recorded 5857 run times for map.flatten!
