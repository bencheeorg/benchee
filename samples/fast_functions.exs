# This benchmark is here to showcase behaviour with too fast functions.
# You can see a lot of it reads _(wrong)_ as the compiler optimizes these cases to return
# constants and thereby doesn't benchmark what you think it does.

range = 1..10
integer1 = :rand.uniform(100)
integer2 = :rand.uniform(100)

Benchee.run(%{
  "Integer addition (wrong)"          => fn -> 1 + 1 end,
  "Integer addition"                  => fn -> integer1 + integer2 end,
  "String concatention (wrong)"       => fn -> "1" <> "1" end,
  "adding a head to an array (wrong)" => fn -> [1 | [1]] end,
  "++ array concat (wrong)"           => fn -> [1] ++ [1] end,
  "noop"                              => fn -> 0 end,
  "Enum.map(10)"                      => fn -> Enum.map(range, fn(i) -> i end) end
}, time: 1, warmup: 1, memory_time: 1)

# See how the median of almost all options is 0 or 1 because they essentially do the same thing.
# Randomizing values prevents these optimizations but is still very fast (see the high standard
# deviation)
#
# tobi@speedy:~$ mix run samples/fast_functions.exs
# Operating System: Linux"
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.6.4
# Erlang 20.3

# Benchmark suite executing with the following configuration:
# warmup: 1 s
# time: 1 s
# memory time: 1 s
# parallel: 1
# inputs: none specified
# Estimated total run time: 21 s


# Benchmarking ++ array concat (wrong)...
# Benchmarking Enum.map(10)...
# Benchmarking Integer addition...
# Benchmarking Integer addition (wrong)...
# Benchmarking String concatention (wrong)...
# Benchmarking adding a head to an array (wrong)...
# Benchmarking noop...

# Name                                        ips        average  deviation         median         99th %
# Integer addition (wrong)               358.83 M        2.79 ns  ±1551.16%           0 ns          36 ns
# noop                                   334.28 M        2.99 ns  ±1397.50%           0 ns          41 ns
# adding a head to an array (wrong)      316.02 M        3.16 ns  ±1198.18%           0 ns          37 ns
# ++ array concat (wrong)                307.24 M        3.25 ns   ±939.38%           0 ns          45 ns
# String concatention (wrong)            268.45 M        3.73 ns   ±845.54%           1 ns          39 ns
# Integer addition                        61.74 M       16.20 ns   ±235.69%          18 ns          59 ns
# Enum.map(10)                             2.26 M      442.05 ns  ±2153.23%         364 ns         813 ns

# Comparison:
# Integer addition (wrong)               358.83 M
# noop                                   334.28 M - 1.07x slower
# adding a head to an array (wrong)      316.02 M - 1.14x slower
# ++ array concat (wrong)                307.24 M - 1.17x slower
# String concatention (wrong)            268.45 M - 1.34x slower
# Integer addition                        61.74 M - 5.81x slower
# Enum.map(10)                             2.26 M - 158.62x slower

# Memory usage statistics:

# Name                                 Memory usage
# Integer addition (wrong)                    616 B
# noop                                        616 B - 1.00x memory usage
# adding a head to an array (wrong)           616 B - 1.00x memory usage
# ++ array concat (wrong)                     616 B - 1.00x memory usage
# String concatention (wrong)                 616 B - 1.00x memory usage
# Integer addition                            616 B - 1.00x memory usage
# Enum.map(10)                                424 B - 0.69x memory usage
