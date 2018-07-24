list = Enum.to_list(1..10_000)
map_fun = fn(i) -> [i, i * i] end

Benchee.run(%{
  "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
  "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten end
}, time: 2, title: "Comparing map.flatten and flat_map")

# $ mix run samples/title.exs
# Operating System: macOS"
# CPU Information: Intel(R) Core(TM) i5-4260U CPU @ 1.40GHz
# Number of Available Cores: 4
# Available memory: 8 GB
# Elixir 1.6.4
# Erlang 20.3

# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 2 s
# memory time: 0 ns
# parallel: 1
# inputs: none specified
# Estimated total run time: 8 s


# Benchmarking flat_map...
# Benchmarking map.flatten...

# *** Comparing map.flatten and flat_map ***

# Name                  ips        average  deviation         median         99th %
# flat_map           1.09 K        0.92 ms    ±34.81%        0.78 ms        1.96 ms
# map.flatten        0.61 K        1.65 ms    ±26.90%        1.45 ms        2.72 ms

# Comparison:
# flat_map           1.09 K
# map.flatten        0.61 K - 1.80x slower
