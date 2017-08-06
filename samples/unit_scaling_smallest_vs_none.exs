# Due to the wide spread of values in unit_scaling.exs there is no difference
# between :none and :smallest -let's fix that here!

list_10k  = 1..10_000    |> Enum.to_list |> Enum.shuffle
list_100k = 1..100_000   |> Enum.to_list |> Enum.shuffle

# options document in README
Benchee.run %{
  "10k"  => fn -> Enum.sort(list_10k) end,
  "100k" => fn -> Enum.sort(list_100k) end,
}, console: [unit_scaling: :none]

# :smallest
# Name           ips        average    deviation         median
# 10k         721.07        1.39 ms     (±8.26%)        1.39 ms
# 100k         55.89       17.89 ms     (±8.77%)       17.21 ms
#
# Comparison:
# 10k         721.07
# 100k         55.89 - 12.90x slower

# :none
# Name           ips        average    deviation         median
# 10k         735.66     1359.32 μs     (±5.81%)        1357 μs
# 100k         55.05    18166.56 μs    (±11.53%)       17062 μs
#
# Comparison:
# 10k         735.66
# 100k         55.05 - 13.36x slower
