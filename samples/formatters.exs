list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

format_fun = fn %{scenarios: scenarios} ->
  IO.puts("")

  Enum.each(scenarios, fn scenario ->
    sample_size = scenario.run_time_data.statistics.sample_size
    IO.puts("Benchee recorded #{sample_size} run times for #{scenario.job_name}!")
  end)
end

Benchee.run(
  %{
    "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
  },
  formatters: [
    format_fun,
    Benchee.Formatters.Console,
    {Benchee.Formatters.Console, extended_statistics: true}
  ]
)

# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.8.1
# Erlang 21.3.2

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
# flat_map           2.41 K      415.64 μs    ±12.00%      406.27 μs      714.89 μs
# map.flatten        1.28 K      781.62 μs    ±18.60%      743.39 μs     1166.22 μs

# Comparison:
# flat_map           2.41 K
# map.flatten        1.28 K - 1.88x slower +365.98 μs

# Name                  ips        average  deviation         median         99th %
# flat_map           2.41 K      415.64 μs    ±12.00%      406.27 μs      714.89 μs
# map.flatten        1.28 K      781.62 μs    ±18.60%      743.39 μs     1166.22 μs

# Comparison:
# flat_map           2.41 K
# map.flatten        1.28 K - 1.88x slower +365.98 μs

# Extended statistics:

# Name                minimum        maximum    sample size                     mode
# flat_map          345.15 μs     1169.01 μs        12.00 K406.39 μs, 405.98 μs, 406
# map.flatten       492.45 μs     1780.14 μs         6.38 K                741.75 μs

# Benchee recorded 12001 run times for flat_map!
# Benchee recorded 6385 run times for map.flatten!
