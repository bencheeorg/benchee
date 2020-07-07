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

# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i5-7200U CPU @ 2.50GHz
# Number of Available Cores: 4
# Available memory: 7.67 GB
# Elixir 1.10.0
# Erlang 22.2.4

# Benchmark suite executing with the following configuration:
# warmup: 100 ms
# time: 300 ms
# memory time: 300 ms
# reduction time: 0 ns
# parallel: 1
# inputs: none specified
# Estimated total run time: 1.40 s

# Benchmarking flat_map...
# Benchmarking map.flatten...

# Name                  ips        average  deviation         median         99th %
# flat_map           1.43 K      699.04 μs    ±39.78%      596.65 μs     1161.17 μs
# map.flatten        1.01 K      987.44 μs    ±22.65%      929.69 μs     1576.78 μs

# Comparison:
# flat_map           1.43 K
# map.flatten        1.01 K - 1.41x slower +288.40 μs

# Memory usage statistics:

# Name           Memory usage
# flat_map             625 KB
# map.flatten       781.25 KB - 1.25x memory usage +156.25 KB

# **All measurements for memory usage were the same**

# Profiling flat_map with cprof...
# Warmup...

#                                                                      CNT
# Total                                                              20005
# Enum                                                               10002  <--
#   Enum.flat_map_list/2                                             10001
#   Enum.flat_map/2                                                      1
# :elixir_compiler_1                                                 10001  <--
#   anonymous fn/1 in :elixir_compiler_1.__FILE__/1                  10000
#   anonymous fn/2 in :elixir_compiler_1.__FILE__/1                      1
# :erlang                                                                2  <--
#   :erlang.trace_pattern/3                                              2
# Profile done over 18327 matching functions

# Profiling map.flatten with cprof...
# Warmup...

#                                                                      CNT
# Total                                                              60008
# :lists                                                             40002  <--
#   :lists.do_flatten/2                                              40001
#   :lists.flatten/1                                                     1
# Enum                                                               10002  <--
#   Enum."-map/2-lists^map/1-0-"/2                                   10001
#   Enum.map/2                                                           1
# :elixir_compiler_1                                                 10001  <--
#   anonymous fn/1 in :elixir_compiler_1.__FILE__/1                  10000
#   anonymous fn/2 in :elixir_compiler_1.__FILE__/1                      1
# :erlang                                                                2  <--
#   :erlang.trace_pattern/3                                              2
# List                                                                   1  <--
#   List.flatten/1                                                       1
# Profile done over 18394 matching functions
