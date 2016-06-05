Benchee.run(%{time: 3},
             [{"Integer addition",          fn -> 1 + 1 end},
              {"String concatention",       fn -> "1" <> "1" end},
              {"adding a head to an array", fn -> [1 | [1]] end},
              {"++ array concat",           fn -> [1] ++ [1] end},
              {"noop",                      fn -> end}])


# Before  adding running fast functions multiple times, these where just too
# damn fast and unstable, take a look at these consecutive runs with integer
# addition going first or last and super high deviations.
#
# tobi@happy ~/github/benchee $ mix run samples/fast_functions.exs
# Compiled lib/benchee/benchmark.ex
# Compiled lib/benchee/formatters/console.ex
# Benchmarking Integer addition...
# Benchmarking Console concatention...
# Benchmarking adding a head to an array...
# Benchmarking ++ array concat...
#
# Name                          ips            average        deviation      median
# Integer addition              18907117533.72 0.00μs         (±42193.83%)   0.0μs
# ++ array concat               10817900457.67 0.00μs         (±32894.19%)   0.0μs
# adding a head to an array     8340878133.10  0.00μs         (±85548.54%)   0.0μs
# String concatention          7283864419.48  0.00μs         (±18597.06%)   0.0μs
#
# Comparison:
# Integer addition              18907117533.72
# ++ array concat               10817900457.67  - 1.75x slower
# adding a head to an array     8340878133.10   - 2.27x slower
# String concatention          7283864419.48   - 2.60x slower
#
# tobi@happy ~/github/benchee $ mix run samples/fast_functions.exs
# Benchmarking Integer addition...
# Benchmarking Console concatention...
# Benchmarking adding a head to an array...
# Benchmarking ++ array concat...
#
# Name                          ips            average        deviation      median
# Integer addition              25569475324.68 0.00μs         (±104824.72%)  0.0μs
# Console concatention          23438869668.25 0.00μs         (±105090.58%)  0.0μs
# adding a head to an array     21958497787.61 0.00μs         (±129525.54%)  0.0μs
# ++ array concat               19056476744.19 0.00μs         (±128997.79%)  0.0μs
#
# Comparison:
# Integer addition              25569475324.68
# String concatention          23438869668.25  - 1.09x slower
# adding a head to an array     21958497787.61  - 1.16x slower
# ++ array concat               19056476744.19  - 1.34x slower
#
# tobi@happy ~/github/benchee $ mix run samples/fast_functions.exs
# Benchmarking Integer addition...
# Benchmarking Console concatention...
# Benchmarking adding a head to an array...
# Benchmarking ++ array concat...
#
# Name                          ips            average        deviation      median
# adding a head to an array     24128392592.59 0.00μs         (±34613.13%)   0.0μs
# String concatention          20195554414.78 0.00μs         (±80819.68%)   0.0μs
# ++ array concat               17945628942.49 0.00μs         (±30830.87%)   0.0μs
# Integer addition              16174678807.95 0.00μs         (±74327.34%)   0.0μs
#
# Comparison:
# adding a head to an array     24128392592.59
# String concatention          20195554414.78  - 1.19x slower
# ++ array concat               17945628942.49  - 1.34x slower
# Integer addition              16174678807.95  - 1.49x slower
