# Due to the wide spread of values in unit_scaling.exs there is no difference
# between :none and :smallest -let's fix that here!

list_10k = 1..10_000 |> Enum.to_list() |> Enum.shuffle()
list_100k = 1..100_000 |> Enum.to_list() |> Enum.shuffle()

# options document in README
Benchee.run(
  %{
    "10k" => fn -> Enum.sort(list_10k) end,
    "100k" => fn -> Enum.sort(list_100k) end
  },
  unit_scaling: :smallest
)

# :smallest
# Name           ips        average  deviation         median         99th %
# 10k         794.29        1.26 ms     ±2.71%        1.25 ms        1.35 ms
# 100k         57.50       17.39 ms     ±3.37%       17.32 ms       19.69 ms

# Comparison:
# 10k         794.29
# 100k         57.50 - 13.81x slower +16.13 ms

# :none
# Name           ips        average  deviation         median         99th %
# 10k         699.28  1430032.96 ns    ±12.25%     1367991 ns  1830810.09 ns
# 100k         57.61 17358597.81 ns     ±3.14% 17264780.50 ns 20125840.48 ns

# Comparison:
# 10k         699.28
# 100k         57.61 - 12.14x slower +15928564.85 ns
