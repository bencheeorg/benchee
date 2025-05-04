list_10k = 1..10_000 |> Enum.to_list() |> Enum.shuffle()
list_100k = 1..100_000 |> Enum.to_list() |> Enum.shuffle()
list_1M = 1..1_000_000 |> Enum.to_list() |> Enum.shuffle()

Benchee.run(
  [
    {"10k", fn -> Statistex.statistics(list_10k) end},
    {"100k", fn -> Statistex.statistics(list_100k) end},
    {"1M", fn -> Statistex.statistics(list_1M) end}
  ],
  memory_time: 2
)

# tobi@qiqi:~/github/benchee(max-sample-size)$ mix run samples/sort_performance.exs
# Operating System: Linux
# CPU Information: AMD Ryzen 9 5900X 12-Core Processor
# Number of Available Cores: 24
# Available memory: 31.26 GB
# Elixir 1.18.3
# Erlang 27.3.2
# JIT enabled: true

# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 5 s
# memory time: 2 s
# reduction time: 0 ns
# parallel: 1
# inputs: none specified
# Estimated total run time: 27 s

# Benchmarking 10k ...
# Benchmarking 100k ...
# Benchmarking 1M ...
# Calculating statistics...
# Formatting results...

# Name           ips        average  deviation         median         99th %
# 10k        1237.97        0.81 ms    ±28.70%        0.73 ms        1.42 ms
# 100k         74.50       13.42 ms    ±40.13%       10.96 ms       31.42 ms
# 1M            6.17      162.05 ms    ±34.38%      146.08 ms      328.83 ms

# Comparison:
# 10k        1237.97
# 100k         74.50 - 16.62x slower +12.62 ms
# 1M            6.17 - 200.61x slower +161.24 ms

# Memory usage statistics:

# Name    Memory usage
# 10k          1.42 MB
# 100k        18.59 MB - 13.09x memory usage +17.17 MB
# 1M         218.22 MB - 153.62x memory usage +216.80 MB

# **All measurements for memory usage were the same**
