list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(
  %{
    "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
  },
  time: 3,
  parallel: 12
)

# The following benchmarks are from a 4-core system with HT, while on a normal
# work load (music, browser, editor, gui etc.) which is not the ideal
# benchmarking environment ;)
#
# The slight performance degradation with parallel: 2 is expected (like most CPUs
# mine has a speed boost when only one CPU is occupied). As parallel processes
# grow then performance degrades because they have to contend with everything
# that is running. Therefore, be aware of the impact running benchmarks in
# parallel has on the results.
#
# The original use case that introduced this was more of a stress test of
# a system.
#
# > I needed to benchmark integration tests for a telephony system we wrote -
# > with this system the tests actually interfere with each other (they're using
# > an Ecto repo) and I wanted to see how far I could push the system as a
# > whole. Making this small change to Benchee worked perfectly for what I
# > needed :)
#
# In the following samples the amount of parallelism is mentioned in the
# configuration:
#
# tobi@speedy:~/github/benchee(redo-samples)$ mix run samples/run_extended_statistics.exs
# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.8.1
# Erlang 21.3.2

# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 10 s
# memory time: 0 ns
# parallel: 1
# inputs: none specified
# Estimated total run time: 24 s

# Benchmarking flat_map...
# Benchmarking map.flatten...

# Name                  ips        average  deviation         median         99th %
# flat_map           2.37 K      421.74 μs    ±14.17%      406.44 μs      758.14 μs
# map.flatten        1.24 K      807.37 μs    ±20.22%      747.94 μs     1311.65 μs

# Comparison:
# flat_map           2.37 K
# map.flatten        1.24 K - 1.91x slower +385.64 μs

# Extended statistics:

# Name                minimum        maximum    sample size                     mode
# flat_map          345.15 μs     1182.74 μs        23.64 K                406.28 μs
# map.flatten       492.78 μs     1925.29 μs        12.36 K741.79 μs, 739.21 μs, 738
# tobi@speedy:~/github/benchee(redo-samples)$ mix run samples/run_parallel.exs
# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.8.1
# Erlang 21.3.2

# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 3 s
# memory time: 0 ns
# parallel: 1
# inputs: none specified
# Estimated total run time: 10 s

# Benchmarking flat_map...
# Benchmarking map.flatten...

# Name                  ips        average  deviation         median         99th %
# flat_map           2.32 K      430.75 μs    ±17.91%      411.92 μs      778.56 μs
# map.flatten        1.28 K      778.52 μs    ±18.28%      747.22 μs     1184.60 μs

# Comparison:
# flat_map           2.32 K
# map.flatten        1.28 K - 1.81x slower +347.77 μs
# tobi@speedy:~/github/benchee(redo-samples)$ mix run samples/run_parallel.exs
# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.8.1
# Erlang 21.3.2

# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 3 s
# memory time: 0 ns
# parallel: 2
# inputs: none specified
# Estimated total run time: 10 s

# Benchmarking flat_map...
# Benchmarking map.flatten...

# Name                  ips        average  deviation         median         99th %
# flat_map           2.02 K      495.11 μs    ±32.48%      410.89 μs      939.02 μs
# map.flatten        1.13 K      882.13 μs    ±28.65%      778.98 μs     1682.38 μs

# Comparison:
# flat_map           2.02 K
# map.flatten        1.13 K - 1.78x slower +387.02 μs
# tobi@speedy:~/github/benchee(redo-samples)$ mix run samples/run_parallel.exs
# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.8.1
# Erlang 21.3.2

# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 3 s
# memory time: 0 ns
# parallel: 3
# inputs: none specified
# Estimated total run time: 10 s

# Benchmarking flat_map...
# Benchmarking map.flatten...

# Name                  ips        average  deviation         median         99th %
# flat_map           1.91 K        0.52 ms    ±35.08%        0.42 ms        0.99 ms
# map.flatten        0.99 K        1.01 ms    ±38.63%        0.90 ms        2.03 ms

# Comparison:
# flat_map           1.91 K
# map.flatten        0.99 K - 1.93x slower +0.49 ms
# tobi@speedy:~/github/benchee(redo-samples)$ mix run samples/run_parallel.exs
# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.8.1
# Erlang 21.3.2

# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 3 s
# memory time: 0 ns
# parallel: 4
# inputs: none specified
# Estimated total run time: 10 s

# Benchmarking flat_map...
# Benchmarking map.flatten...

# Name                  ips        average  deviation         median         99th %
# flat_map           1.39 K        0.72 ms    ±38.55%        0.84 ms        1.46 ms
# map.flatten        0.97 K        1.03 ms    ±31.74%        0.94 ms        1.91 ms

# Comparison:
# flat_map           1.39 K
# map.flatten        0.97 K - 1.44x slower +0.31 ms
# tobi@speedy:~/github/benchee(redo-samples)$ mix run samples/run_parallel.exs
# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.8.1
# Erlang 21.3.2

# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 3 s
# memory time: 0 ns
# parallel: 8
# inputs: none specified
# Estimated total run time: 10 s

# Benchmarking flat_map...
# Benchmarking map.flatten...

# Name                  ips        average  deviation         median         99th %
# flat_map           831.66        1.20 ms   ±100.08%        0.93 ms        5.32 ms
# map.flatten        420.88        2.38 ms    ±81.19%        1.62 ms       10.09 ms

# Comparison:
# flat_map           831.66
# map.flatten        420.88 - 1.98x slower +1.17 ms
# tobi@speedy:~/github/benchee(redo-samples)$ mix run samples/run_parallel.exs
# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.8.1
# Erlang 21.3.2

# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 3 s
# memory time: 0 ns
# parallel: 12
# inputs: none specified
# Estimated total run time: 10 s

# Benchmarking flat_map...
# Benchmarking map.flatten...

# Name                  ips        average  deviation         median         99th %
# flat_map           552.33        1.81 ms    ±67.19%        1.63 ms        6.06 ms
# map.flatten        326.31        3.06 ms    ±60.55%        2.62 ms        9.58 ms

# Comparison:
# flat_map           552.33
# map.flatten        326.31 - 1.69x slower +1.25 ms
