# This benchmark is not entirely recommended as the functions are way too fast
# it's meant to show how this is not feasible or show improvements when I get
# a new idea to improve this.

range = 1..10
Benchee.run(%{
  "Integer addition"          => fn -> 1 + 1 end,
  "String concatention"       => fn -> "1" <> "1" end,
  "adding a head to an array" => fn -> [1 | [1]] end,
  "++ array concat"           => fn -> [1] ++ [1] end,
  "noop"                      => fn -> 0 end,
  "Enum.map(10)"              => fn -> Enum.map(range, fn(i) -> i end) end
}, time: 1, warmup: 1, memory_time: 1)

#
# Before  adding running fast functions multiple times, these where just too
# damn fast and unstable, take a look at these consecutive runs with integer
# addition going first or last and super high deviations.
#
# tobi@happy ~/github/benchee $ mix run samples/fast_functions.exs
#
# ** lots of complains about too fast function execution **
#
# Name                          ips            average        deviation      median
# ++ array concat               82969267.26    0.0121μs       (±16.71%)      0.0120μs
# adding a head to an array     82868502.33    0.0121μs       (±100.61%)     0.0120μs
# String concatention           82845306.42    0.0121μs       (±62.76%)      0.0120μs
# Integer addition              81872809.30    0.0122μs       (±24.77%)      0.0120μs
# noop                          81112598.69    0.0123μs       (±147.62%)     0.0120μs
# Enum.map (10)                 1423971.66     0.70μs         (±104.11%)     0.64μs
#
# Comparison:
# ++ array concat               82969267.26
# adding a head to an array     82868502.33     - 1.00x slower
# String concatention           82845306.42     - 1.00x slower
# Integer addition              81872809.30     - 1.01x slower
# noop                          81112598.69     - 1.02x slower
# Enum.map (10)                 1423971.66      - 58.27x slower
#
# ---------------------------------
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
# -------------------------------------------------------------------------
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
# -------------------------------------------------------------------------
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
