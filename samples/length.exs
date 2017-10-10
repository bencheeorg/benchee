Benchee.run %{
  "length" => fn(list) -> length(list) end,
  "Enum.count" => fn(list) -> Enum.count(list) end
}, inputs: %{
  "10k"  => Enum.to_list(1..10_000),
  "100k" => Enum.to_list(1..100_000),
  "1M"   => Enum.to_list(1..1_000_000),
  "10M"  => Enum.to_list(1..10_000_000)
}

# tobi@comfy ~/github/benchee $ mix run samples/length.exs 
# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz
# Number of Available Cores: 4
# Available memory: 7.68 GB
# Elixir 1.5.1
# Erlang 20.0
# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 5 s
# parallel: 1
# inputs: 100k, 10M, 10k, 1M
# Estimated total run time: 3.73 min



# Benchmarking with input 100k:
# Benchmarking Enum.count...

# Benchmarking with input 10M:
# Benchmarking Enum.count...

# Benchmarking with input 10k:
# Benchmarking Enum.count...

# Benchmarking with input 1M:
# Benchmarking Enum.count...

# Benchmarking with input 100k:
# Benchmarking length...

# Benchmarking with input 10M:
# Benchmarking length...

# Benchmarking with input 10k:
# Benchmarking length...

# Benchmarking with input 1M:
# Benchmarking length...

# ##### With input 100k #####
# Name                 ips        average  deviation         median
# length            1.60 K      624.26 μs    ±20.42%         603 μs
# Enum.count        1.60 K      625.19 μs    ±20.73%         604 μs

# Comparison: 
# length            1.60 K
# Enum.count        1.60 K - 1.00x slower

# ##### With input 10M #####
# Name                 ips        average  deviation         median
# length             31.91       31.34 ms     ±4.54%       30.61 ms
# Enum.count         31.85       31.39 ms     ±4.52%       30.64 ms

# Comparison: 
# length             31.91
# Enum.count         31.85 - 1.00x slower

# ##### With input 10k #####
# Name                 ips        average  deviation         median
# Enum.count       22.23 K       44.98 μs    ±38.44%          43 μs
# length           22.12 K       45.21 μs    ±38.62%          43 μs

# Comparison: 
# Enum.count       22.23 K
# length           22.12 K - 1.01x slower

# ##### With input 1M #####
# Name                 ips        average  deviation         median
# length            223.27        4.48 ms    ±10.30%        4.32 ms
# Enum.count        222.74        4.49 ms    ±10.29%        4.32 ms

# Comparison: 
# length            223.27
# Enum.count        222.74 - 1.00x slower
