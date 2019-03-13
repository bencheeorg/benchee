# When passing a flag parallel with value >1 then multiple processes
# will be handled for benchmarking provided function.

Benchee.run(%{"one" => fn -> :timer.sleep(1000) end}, parallel: 1, time: 10)
Benchee.run(%{"three" => fn -> :timer.sleep(1000) end}, parallel: 3, time: 10)
Benchee.run(%{"five" => fn -> :timer.sleep(1000) end}, parallel: 5, time: 10)

# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 16.37 GB
# Elixir 1.5.0
# Erlang 20.0
# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 10 s
# parallel: 1
# inputs: none specified
# Estimated total run time: 12 s
#
#
# Benchmarking one...
#
# Name           ips        average  deviation         median
# one           1.00         1.00 s     ±0.00%         1.00 s
# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 16.37 GB
# Elixir 1.5.0
# Erlang 20.0
# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 10 s
# parallel: 3
# inputs: none specified
# Estimated total run time: 12 s
#
#
# Benchmarking three...
#
# Name            ips        average  deviation         median
# three          1.00         1.00 s     ±0.01%         1.00 s
# three          1.00         1.00 s     ±0.01%         1.00 s
# three          1.00         1.00 s     ±0.01%         1.00 s
#
# Comparison:
# three          1.00
# three          1.00 - 1.00x slower
# three          1.00 - 1.00x slower
# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 16.37 GB
# Elixir 1.5.0
# Erlang 20.0
# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 10 s
# parallel: 5
# inputs: none specified
# Estimated total run time: 12 s
#
#
# Benchmarking five...
#
# Name           ips        average  deviation         median
# five          1.00         1.00 s     ±0.00%         1.00 s
# five          1.00         1.00 s     ±0.00%         1.00 s
# five          1.00         1.00 s     ±0.00%         1.00 s
# five          1.00         1.00 s     ±0.00%         1.00 s
# five          1.00         1.00 s     ±0.00%         1.00 s
#
# Comparison:
# five          1.00
# five          1.00 - 1.00x slower
# five          1.00 - 1.00x slower
# five          1.00 - 1.00x slower
# five          1.00 - 1.00x slower
