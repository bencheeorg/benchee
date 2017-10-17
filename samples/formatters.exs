list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

format_fun = fn(%{scenarios: scenarios}) ->
  IO.puts ""
  Enum.each scenarios, fn(scenario) ->
    sample_size = scenario.run_time_statistics.sample_size
    IO.puts "Benchee recorded #{sample_size} run times for #{scenario.job_name}!"
  end
end

Benchee.run(%{
  "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten end},
  formatters: [
    format_fun,
    # you can choose one or the other, but module style is parallelizable
    &Benchee.Formatters.Console.output/1,
    Benchee.Formatters.Console
  ]
)

# Yes we print it out twice now...
#
# tobi@comfy ~/github/benchee $ mix run samples/formatters.exs
# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz
# Number of Available Cores: 4
# Available memory: 7.68 GB
# Elixir 1.5.2
# Erlang 20.0
# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 5 s
# parallel: 1
# inputs: none specified
# Estimated total run time: 14 s


# Benchmarking flat_map...
# Benchmarking map.flatten...

# Name                  ips        average  deviation         median         99th %
# flat_map           950.60        1.05 ms    ±17.71%        1.00 ms        1.86 ms
# map.flatten        506.34        1.98 ms    ±23.04%        1.83 ms        3.50 ms

# Comparison:
# flat_map           950.60
# map.flatten        506.34 - 1.88x slower

# Benchee recorded 4739 run times for flat_map!
# Benchee recorded 2526 run times for map.flatten!

# Name                  ips        average  deviation         median         99th %
# flat_map           950.60        1.05 ms    ±17.71%        1.00 ms        1.86 ms
# map.flatten        506.34        1.98 ms    ±23.04%        1.83 ms        3.50 ms

# Comparison:
# flat_map           950.60
# map.flatten        506.34 - 1.88x slower
