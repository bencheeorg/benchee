list = Enum.to_list(1..10_000)
map_fun = fn i -> [i, i * i] end

Benchee.run(
  %{
    "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
  },
  warmup: 0.1,
  time: 0.3,
  memory_time: 0.3,
  profile_after: true
)

Benchee.run(
  %{
    "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
    "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
  },
  warmup: 0.1,
  time: 0.3,
  memory_time: 0.3,
  profile_after: :tprof
)

# tobi@qiqi:~/github/benchee(main)$ mix run samples/fast_with_profiling.exs
# Compiling 2 files (.ex)
# Operating System: Linux
# CPU Information: AMD Ryzen 9 5900X 12-Core Processor
# Number of Available Cores: 24
# Available memory: 31.26 GB
# Elixir 1.17.3
# Erlang 27.1
# JIT enabled: true

# Benchmark suite executing with the following configuration:
# warmup: 100 ms
# time: 300 ms
# memory time: 300 ms
# reduction time: 0 ns
# parallel: 1
# inputs: none specified
# Estimated total run time: 1 s 400 ms

# Benchmarking flat_map ...
# Benchmarking map.flatten ...
# Calculating statistics...
# Formatting results...

# Name                  ips        average  deviation         median         99th %
# flat_map           2.24 K      447.25 μs    ±53.59%      322.59 μs     1096.32 μs
# map.flatten        1.61 K      620.76 μs    ±38.00%      689.02 μs      963.44 μs

# Comparison:
# flat_map           2.24 K
# map.flatten        1.61 K - 1.39x slower +173.51 μs

# Memory usage statistics:

# Name           Memory usage
# flat_map             625 KB
# map.flatten       781.25 KB - 1.25x memory usage +156.25 KB

# **All measurements for memory usage were the same**

# Profiling flat_map with eprof...

# Profile results of #PID<0.1617.0>
# #                                               CALLS     % TIME µS/CALL
# Total                                           30004 100.0 3779    0.13
# Enum.flat_map/2                                     1  0.00    0    0.00
# anonymous fn/2 in :elixir_compiler_2.__FILE__/1     1  0.00    0    0.00
# :erlang.apply/2                                     1  0.03    1    1.00
# :erlang.++/2                                    10000 14.58  551    0.06
# Enum.flat_map_list/2                            10001 42.13 1592    0.16
# anonymous fn/1 in :elixir_compiler_2.__FILE__/1 10000 43.27 1635    0.16

# Profile done over 6 matching functions

# Profiling map.flatten with eprof...

# Profile results of #PID<0.1619.0>
# #                                               CALLS     % TIME µS/CALL
# Total                                           60007 100.0 5281    0.09
# List.flatten/1                                      1  0.00    0    0.00
# Enum.map/2                                          1  0.00    0    0.00
# :lists.flatten/1                                    1  0.00    0    0.00
# :erlang.apply/2                                     1  0.04    2    2.00
# anonymous fn/2 in :elixir_compiler_2.__FILE__/1     1  0.04    2    2.00
# anonymous fn/1 in :elixir_compiler_2.__FILE__/1 10000 19.90 1051    0.11
# Enum."-map/2-lists^map/1-1-"/2                  10001 26.60 1405    0.14
# :lists.do_flatten/2                             40001 53.42 2821    0.07

# Profile done over 8 matching functions
# Operating System: Linux
# CPU Information: AMD Ryzen 9 5900X 12-Core Processor
# Number of Available Cores: 24
# Available memory: 31.26 GB
# Elixir 1.17.3
# Erlang 27.1
# JIT enabled: true

# Benchmark suite executing with the following configuration:
# warmup: 100 ms
# time: 300 ms
# memory time: 300 ms
# reduction time: 0 ns
# parallel: 1
# inputs: none specified
# Estimated total run time: 1 s 400 ms

# Benchmarking flat_map ...
# Benchmarking map.flatten ...
# Calculating statistics...
# Formatting results...

# Name                  ips        average  deviation         median         99th %
# flat_map           2.42 K      412.87 μs    ±48.32%      323.59 μs      737.84 μs
# map.flatten        1.72 K      582.68 μs    ±35.48%      673.13 μs      987.99 μs

# Comparison:
# flat_map           2.42 K
# map.flatten        1.72 K - 1.41x slower +169.81 μs

# Memory usage statistics:

# Name           Memory usage
# flat_map             625 KB
# map.flatten       781.25 KB - 1.25x memory usage +156.25 KB

# **All measurements for memory usage were the same**

# Profiling flat_map with tprof...

# Profile results of #PID<0.3062.0>
# #                                               CALLS      % TIME µS/CALL
# Total                                           30003 100.00 3686    0.12
# Enum.flat_map/2                                     1   0.00    0    0.00
# anonymous fn/2 in :elixir_compiler_2.__FILE__/1     1   0.05    2    2.00
# :erlang.++/2                                    10000  14.46  533    0.05
# anonymous fn/1 in :elixir_compiler_2.__FILE__/1 10000  33.67 1241    0.12
# Enum.flat_map_list/2                            10001  51.82 1910    0.19

# Profile done over 5 matching functions

# Profiling map.flatten with tprof...

# Profile results of #PID<0.3064.0>
# #                                               CALLS      % TIME µS/CALL
# Total                                           60006 100.00 5316    0.09
# List.flatten/1                                      1   0.00    0    0.00
# Enum.map/2                                          1   0.00    0    0.00
# :lists.flatten/1                                    1   0.00    0    0.00
# anonymous fn/2 in :elixir_compiler_2.__FILE__/1     1   0.06    3    3.00
# anonymous fn/1 in :elixir_compiler_2.__FILE__/1 10000  24.72 1314    0.13
# Enum."-map/2-lists^map/1-1-"/2                  10001  25.81 1372    0.14
# :lists.do_flatten/2                             40001  49.42 2627    0.07
