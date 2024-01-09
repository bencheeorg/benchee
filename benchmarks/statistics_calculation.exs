# Purpose is to figure out how many samples we can deal with without reaching a signifcant slow down
# intent is to inform picking a sensible "max_sample_count" value.
# Both from a time perspective, but also from a memory consumption perspective.

random_list = fn size ->
  # work on a huge range, as our values are in ns and hence are huge
  for _i <- 1..size, do: :rand.uniform(999_999_999_999)
end

ten_k = random_list.(10_000)
hundred_k = random_list.(100_000)
five_hundred_k = random_list.(500_000)
million = random_list.(1_000_000)
ten_m = random_list.(10_000_000)

opts = [percentiles: [50, 99]]

Benchee.run(
  %{
    "10k" => fn -> Statistex.statistics(ten_k, opts) end,
    "100k" => fn -> Statistex.statistics(hundred_k, opts) end,
    "500k" => fn -> Statistex.statistics(five_hundred_k, opts) end,
    "1M" => fn -> Statistex.statistics(million, opts) end,
    "10M" => fn -> Statistex.statistics(ten_m, opts) end,
  },
  warmup: 5,
  time: 40,
  memory_time: 5,
  formatters: [{Benchee.Formatters.Console, extended_statistics: true}]
)

# Operating System: Linux
# CPU Information: AMD Ryzen 9 5900X 12-Core Processor
# Number of Available Cores: 24
# Available memory: 31.25 GB
# Elixir 1.16.0
# Erlang 26.2.1
# JIT enabled: true

# Benchmark suite executing with the following configuration:
# warmup: 5 s
# time: 40 s
# memory time: 5 s
# reduction time: 0 ns
# parallel: 1
# inputs: none specified
# Estimated total run time: 4 min 10 s

# Benchmarking 100k ...
# Benchmarking 10M ...
# Benchmarking 10k ...
# Benchmarking 1M ...
# Benchmarking 500k ...
# Calculating statistics...
# Formatting results...

# Name           ips        average  deviation         median         99th %
# 10k         263.83        3.79 ms    ±13.71%        3.74 ms        5.04 ms
# 100k         14.65       68.25 ms     ±7.85%       71.74 ms       80.17 ms
# 500k          2.13      470.50 ms    ±11.84%      455.84 ms      567.49 ms
# 1M            0.95     1047.74 ms     ±8.72%     1048.59 ms     1250.94 ms
# 10M         0.0753    13285.55 ms     ±5.62%    13556.51 ms    13840.21 ms

# Comparison:
# 10k         263.83
# 100k         14.65 - 18.01x slower +64.46 ms
# 500k          2.13 - 124.13x slower +466.71 ms
# 1M            0.95 - 276.43x slower +1043.95 ms
# 10M         0.0753 - 3505.15x slower +13281.76 ms

# Extended statistics:

# Name         minimum        maximum    sample size                     mode
# 10k          2.86 ms        7.61 ms        10.55 K                  3.60 ms
# 100k        62.04 ms       93.72 ms            587                 63.04 ms
# 500k       363.21 ms      567.49 ms             85                     None
# 1M         851.31 ms     1250.94 ms             39                     None
# 10M      12188.97 ms    13840.21 ms              4                     None

# Memory usage statistics:

# Name    Memory usage
# 10k          4.95 MB
# 100k        71.59 MB - 14.47x memory usage +66.64 MB
# 500k       431.15 MB - 87.14x memory usage +426.20 MB
# 1M         928.47 MB - 187.65x memory usage +923.52 MB
# 10M      10677.42 MB - 2158.00x memory usage +10672.47 MB

# **All measurements for memory usage were the same**
