# This benchmark is here to showcase behaviour with too fast functions.
# You can see a lot of it reads _(wrong)_ as the compiler optimizes these cases to return
# constants and thereby doesn't benchmark what you think it does.

range = 1..10
integer1 = :rand.uniform(100)
integer2 = :rand.uniform(100)

Benchee.run(
  %{
    "Integer addition (wrong)" => fn -> 1 + 1 end,
    "Integer addition" => fn -> integer1 + integer2 end,
    "String concatention (wrong)" => fn -> "1" <> "1" end,
    "adding a head to an array (wrong)" => fn -> [1 | [1]] end,
    "++ array concat (wrong)" => fn -> [1] ++ [1] end,
    "noop" => fn -> 0 end,
    "Enum.map(10)" => fn -> Enum.map(range, fn i -> i end) end
  },
  time: 1,
  warmup: 1,
  memory_time: 1,
  formatters: [{Benchee.Formatters.Console, extended_statistics: true}]
)

# See how the median of almost all options is 0 or 1 because they essentially do the same thing.
# Randomizing values prevents these optimizations but is still very fast (see the high standard
# deviation)
#
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.8.1
# Erlang 21.2.7

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
# String concatention (wrong)           1008.75 M        0.99 ns  ±3006.13%           0 ns          23 ns
# ++ array concat (wrong)                715.26 M        1.40 ns  ±1900.44%           0 ns          28 ns
# adding a head to an array (wrong)      681.71 M        1.47 ns  ±1760.70%           0 ns          34 ns
# noop                                   598.00 M        1.67 ns  ±7354.09%           0 ns          22 ns
# Integer addition (wrong)               560.71 M        1.78 ns  ±6908.19%           0 ns          28 ns
# Integer addition                       361.27 M        2.77 ns  ±1187.75%           0 ns          43 ns
# Enum.map(10)                             2.23 M      448.05 ns  ±3255.01%         351 ns         760 ns

# Comparison:
# String concatention (wrong)           1008.75 M
# ++ array concat (wrong)                715.26 M - 1.41x slower +0.41 ns
# adding a head to an array (wrong)      681.71 M - 1.48x slower +0.48 ns
# noop                                   598.00 M - 1.69x slower +0.68 ns
# Integer addition (wrong)               560.71 M - 1.80x slower +0.79 ns
# Integer addition                       361.27 M - 2.79x slower +1.78 ns
# Enum.map(10)                             2.23 M - 451.97x slower +447.06 ns

# Extended statistics:

# Name                                      minimum        maximum    sample size                     mode
# String concatention (wrong)                  0 ns        9236 ns         1.55 M                     0 ns
# ++ array concat (wrong)                      0 ns        9246 ns         1.55 M                     0 ns
# adding a head to an array (wrong)            0 ns        9019 ns         1.55 M                     0 ns
# noop                                         0 ns       62524 ns         1.55 M                     0 ns
# Integer addition (wrong)                     0 ns       67609 ns         1.55 M                     0 ns
# Integer addition                             0 ns        9297 ns         1.55 M                     0 ns
# Enum.map(10)                               330 ns     9091442 ns       942.59 K                   348 ns

# Memory usage statistics:

# Name                                 Memory usage
# String concatention (wrong)                   0 B
# ++ array concat (wrong)                       0 B - 1.00x memory usage +0 B
# adding a head to an array (wrong)             0 B - 1.00x memory usage +0 B
# noop                                          0 B - 1.00x memory usage +0 B
# Integer addition (wrong)                      0 B - 1.00x memory usage +0 B
# Integer addition                              0 B - 1.00x memory usage +0 B
# Enum.map(10)                                424 B - ∞ x memory usage +424 B

# **All measurements for memory usage were the same**
