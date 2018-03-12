defmodule Fib do
  def fib(0) do 0 end
  def fib(1) do 1 end
  def fib(n) do fib(n-1) + fib(n-2) end
end

Benchee.run(%{
  "40 fibonacci numbers" => fn -> Fib.fib(40) end,
  "47 fibonacci numbers" => fn -> Fib.fib(47) end
}, time: 10, warmup: 0)

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
#
#
# Benchmarking 40 fibonacci numbers...
# Benchmarking 47 fibonacci numbers...
#
# Name                           ips        average  deviation         median         99th %
# 40 fibonacci numbers         0.171     0.0975 min     ±0.57%     0.0975 min     0.0980 min
# 47 fibonacci numbers       0.00612       2.72 min     ±0.00%       2.72 min       2.72 min
#
# Comparison:
# 40 fibonacci numbers         0.171
# 47 fibonacci numbers       0.00612 - 27.92x slower
