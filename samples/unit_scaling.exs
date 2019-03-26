list_10 = 1..10 |> Enum.to_list() |> Enum.shuffle()
list_100 = 1..100 |> Enum.to_list() |> Enum.shuffle()
list_1k = 1..1_000 |> Enum.to_list() |> Enum.shuffle()
list_10k = 1..10_000 |> Enum.to_list() |> Enum.shuffle()
list_100k = 1..100_000 |> Enum.to_list() |> Enum.shuffle()
list_1M = 1..1_000_000 |> Enum.to_list() |> Enum.shuffle()
list_5M = 1..5_000_000 |> Enum.to_list() |> Enum.shuffle()

# options documented in README
Benchee.run(
  %{
    "10" => fn -> Enum.sort(list_10) end,
    "100" => fn -> Enum.sort(list_100) end,
    "1k" => fn -> Enum.sort(list_1k) end,
    "10k" => fn -> Enum.sort(list_10k) end,
    "100k" => fn -> Enum.sort(list_100k) end,
    "1M" => fn -> Enum.sort(list_1M) end,
    "5M" => fn -> Enum.sort(list_5M) end
  },
  warmup: 1,
  time: 2,
  unit_scaling: :none
)

# With :best scaling (default)
# Name           ips        average  deviation         median         99th %
# 10     54339465.83     0.00002 ms ±59170.09%           0 ms           0 ms
# 100      274669.84     0.00364 ms    ±71.69%     0.00353 ms     0.00618 ms
# 1k        10610.90      0.0942 ms     ±7.50%      0.0924 ms       0.133 ms
# 10k         728.48        1.37 ms     ±3.88%        1.36 ms        1.56 ms
# 100k         54.92       18.21 ms     ±6.44%       17.93 ms       24.40 ms
# 1M            3.33      300.22 ms     ±3.56%      299.84 ms      321.05 ms
# 5M            0.62     1601.88 ms     ±1.81%     1601.88 ms     1622.44 ms

# Comparison:
# 10     54339465.83
# 100      274669.84 - 197.84x slower +0.00362 ms
# 1k        10610.90 - 5121.10x slower +0.0942 ms
# 10k         728.48 - 74592.88x slower +1.37 ms
# 100k         54.92 - 989461.84x slower +18.21 ms
# 1M            3.33 - 16313992.34x slower +300.22 ms
# 5M            0.62 - 87045544.33x slower +1601.88 ms

# With :largest scaling
# Name           ips        average  deviation         median         99th %
# 10         26.50 M      0.00000 s ±31888.41%            0 s      0.00000 s
# 100         0.26 M      0.00000 s    ±65.08%      0.00000 s      0.00001 s
# 1k        0.0106 M      0.00009 s     ±7.10%      0.00009 s      0.00011 s
# 10k      0.00072 M      0.00139 s     ±5.50%      0.00136 s      0.00162 s
# 100k     0.00005 M       0.0184 s     ±7.38%       0.0180 s       0.0259 s
# 1M       0.00000 M         0.29 s     ±2.55%         0.29 s         0.30 s
# 5M       0.00000 M         1.57 s     ±0.00%         1.57 s         1.57 s

# Comparison:
# 10         26.50 M
# 100         0.26 M - 102.14x slower +0.00000 s
# 1k        0.0106 M - 2502.96x slower +0.00009 s
# 10k      0.00072 M - 36778.23x slower +0.00139 s
# 100k     0.00005 M - 488121.76x slower +0.0184 s
# 1M       0.00000 M - 7682423.21x slower +0.29 s
# 5M       0.00000 M - 41519805.39x slower +1.57 s

# With :smallest scaling
# Name           ips        average  deviation         median         99th %
# 10     28235291.15       35.42 ns ±41613.65%           0 ns           0 ns
# 100      265789.35     3762.38 ns   ±150.11%        3600 ns     5725.10 ns
# 1k        10852.43    92145.25 ns     ±6.48%    91483.50 ns   110076.41 ns
# 10k         727.98  1373671.11 ns     ±6.10%  1349783.50 ns  1852423.85 ns
# 100k         57.06 17526359.86 ns     ±4.17%    17360028 ns 21152683.36 ns
# 1M            3.35298758918.29 ns     ±1.99%   300828679 ns   304052431 ns
# 5M            0.631594076577.50 n     ±1.37%1594076577.50 n  1609545725 ns

# Comparison:
# 10     28235291.15
# 100      265789.35 - 106.23x slower +3726.96 ns
# 1k        10852.43 - 2601.75x slower +92109.83 ns
# 10k         727.98 - 38786.00x slower +1373635.70 ns
# 100k         57.06 - 494861.87x slower +17526324.44 ns
# 1M            3.35 - 8435545.04x slower +298758882.87 ns
# 5M            0.63 - 45009216.28x slower +1594076542.08 ns

# With :none scaling
# Name           ips        average  deviation         median         99th %
# 10     22559861.17       44.33 ns ±36545.13%           0 ns           0 ns
# 100      274192.56     3647.07 ns    ±72.97%        3556 ns        5734 ns
# 1k        10602.13    94320.70 ns    ±11.69%       92365 ns   108881.82 ns
# 10k         747.65  1337530.97 ns     ±9.24%     1271344 ns  1777959.76 ns
# 100k         55.18 18123591.72 ns     ±6.20%    17783950 ns 23599979.00 ns
# 1M            3.36297466609.43 ns     ±2.22%   296495374 ns   311766061 ns
# 5M            0.63  1582891081 ns     ±0.20%  1582891081 ns  1585160748 ns

# Comparison:
# 10     22559861.17
# 100      274192.56 - 82.28x slower +3602.75 ns
# 1k        10602.13 - 2127.86x slower +94276.37 ns
# 10k         747.65 - 30174.51x slower +1337486.64 ns
# 100k         55.18 - 408865.71x slower +18123547.39 ns
# 1M            3.36 - 6710805.41x slower +297466565.10 ns
# 5M            0.63 - 35709803.03x slower +1582891036.67 ns
