defmodule Fib do
  def fib(0) do 0 end
  def fib(1) do 1 end
  def fib(n) do "#{fib(n-1)} #{fib(n-2)}" end
end

Benchee.run(%{
  "35 fibonacci numbers" => fn -> Fib.fib(35) end,
  "43 fibonacci numbers" => fn -> Fib.fib(43) end
}, time: 10, warmup: 0, measure_memory: true)

# Operating System: macOS
# CPU Information: Intel(R) Core(TM) i5-4260U CPU @ 1.40GHz
# Number of Available Cores: 4
# Available memory: 8 GB
# Elixir 1.6.0
# Erlang 20.2
# Benchmark suite executing with the following configuration:
# warmup: 0 μs
# time: 10 s
# parallel: 1
# inputs: none specified
# Estimated total run time: 20 s


# Benchmarking 35 fibonacci numbers...
# Benchmarking 43 fibonacci numbers...

# Name                           ips        average  deviation         median         99th %
# 35 fibonacci numbers         0.164      0.102 min     ±0.00%      0.102 min      0.102 min
# 43 fibonacci numbers       0.00343       4.86 min     ±0.00%       4.86 min       4.86 min

# Comparison:
# 35 fibonacci numbers         0.164
# 43 fibonacci numbers       0.00343 - 47.92x slower

# Memory usage statistics:

# Name                    Memory usage
# 35 fibonacci numbers         1.15 GB
# 43 fibonacci numbers        53.78 GB - 46.98x memory usage

# **All measurements for memory usage were the same**
