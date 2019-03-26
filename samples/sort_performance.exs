list_10k = 1..10_000 |> Enum.to_list() |> Enum.shuffle()
list_100k = 1..100_000 |> Enum.to_list() |> Enum.shuffle()

Benchee.run(%{"10k" => fn -> Enum.sort(list_10k) end, "100k" => fn -> Enum.sort(list_100k) end})

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

# Benchmarking 100k...
# Benchmarking 10k...

# Name           ips        average  deviation         median         99th %
# 10k         722.79        1.38 ms    ±10.21%        1.37 ms        1.77 ms
# 100k         56.70       17.64 ms     ±6.38%       17.34 ms       22.84 ms

# Comparison:
# 10k         722.79
# 100k         56.70 - 12.75x slower +16.25 ms
