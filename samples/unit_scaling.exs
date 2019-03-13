list_10 = 1..10 |> Enum.to_list() |> Enum.shuffle()
list_100 = 1..100 |> Enum.to_list() |> Enum.shuffle()
list_1k = 1..1_000 |> Enum.to_list() |> Enum.shuffle()
list_10k = 1..10_000 |> Enum.to_list() |> Enum.shuffle()
list_100k = 1..100_000 |> Enum.to_list() |> Enum.shuffle()
list_1M = 1..1_000_000 |> Enum.to_list() |> Enum.shuffle()

# options documented in README
Benchee.run(
  %{
    "10" => fn -> Enum.sort(list_10) end,
    "100" => fn -> Enum.sort(list_100) end,
    "1k" => fn -> Enum.sort(list_1k) end,
    "10k" => fn -> Enum.sort(list_10k) end,
    "100k" => fn -> Enum.sort(list_100k) end,
    "1M" => fn -> Enum.sort(list_1M) end
  },
  console: [unit_scaling: :largest]
)

# With :best scaling (default)
# Name           ips        average    deviation         median
# 10      3060864.77     0.00033 ms    (±19.20%)     0.00032 ms
# 100      191617.19     0.00522 ms    (±12.19%)     0.00510 ms
# 1k         8221.08       0.122 ms     (±8.99%)       0.118 ms
# 10k         574.83        1.74 ms     (±9.15%)        1.71 ms
# 100k         41.97       23.83 ms     (±9.24%)       23.13 ms
# 1M            3.20      312.35 ms     (±3.59%)      311.03 ms

# With :largest scaling
# Name           ips        average    deviation         median
# 10          3.85 M     0.00026 ms    (±21.04%)     0.00025 ms
# 100        0.188 M     0.00532 ms    (±13.52%)     0.00520 ms
# 1k       0.00839 M       0.119 ms     (±8.39%)       0.118 ms
# 10k      0.00058 M        1.71 ms     (±8.90%)        1.69 ms
# 100k     0.00004 M       22.29 ms     (±9.28%)       21.35 ms
# 1M       0.00000 M      306.68 ms     (±3.33%)      308.76 ms

# With :smallest scaling
# Name           ips        average    deviation         median
# 10      3398103.02        0.29 μs    (±20.77%)        0.29 μs
# 100      196741.99        5.08 μs    (±13.06%)           5 μs
# 1k         8341.69      119.88 μs     (±8.84%)         118 μs
# 10k         577.54     1731.49 μs     (±9.98%)        1693 μs
# 100k         42.87    23326.77 μs    (±12.01%)    21974.50 μs
# 1M            3.27   305768.81 μs     (±3.05%)   306229.50 μs

# With :none scaling
# Name           ips        average    deviation         median
# 10      3587943.97        0.28 μs    (±21.22%)        0.27 μs
# 100      201976.59        4.95 μs    (±14.42%)        4.80 μs
# 1k         8480.32      117.92 μs     (±8.46%)         117 μs
# 10k         560.89     1782.89 μs    (±10.70%)        1742 μs
# 100k         42.16    23717.72 μs    (±12.55%)    22433.50 μs
# 1M            3.22   310699.93 μs     (±3.96%)      303537 μs
