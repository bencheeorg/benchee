# Intentionally not a real fibonacci to make it both slower and more memory hungry
defmodule Fib do
  def fib(0), do: 0
  def fib(1), do: 1
  def fib(n), do: "#{fib(n - 1)} #{fib(n - 2)}"
end

Benchee.run(
  %{
    "35 fibonacci numbers" => fn -> Fib.fib(35) end,
    "43 fibonacci numbers" => fn -> Fib.fib(43) end
  },
  time: 10,
  warmup: 0,
  memory_time: 10
)

# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.8.1
# Erlang 21.3.2

# Benchmark suite executing with the following configuration:
# warmup: 0 ns
# time: 10 s
# memory time: 10 s
# parallel: 1
# inputs: none specified
# Estimated total run time: 40 s

# Benchmarking 35 fibonacci numbers...
# Benchmarking 43 fibonacci numbers...

# Name                           ips        average  deviation         median         99th %
# 35 fibonacci numbers          0.32     0.0525 min     ±1.49%     0.0525 min     0.0534 min
# 43 fibonacci numbers       0.00674       2.47 min     ±0.00%       2.47 min       2.47 min

# Comparison:
# 35 fibonacci numbers          0.32
# 43 fibonacci numbers       0.00674 - 47.06x slower +2.42 min

# Memory usage statistics:

# Name                    Memory usage
# 35 fibonacci numbers         1.14 GB
# 43 fibonacci numbers        53.78 GB - 46.98x memory usage +52.64 GB

# **All measurements for memory usage were the same**
