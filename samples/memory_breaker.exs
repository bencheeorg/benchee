# Original code by Michal Muskala
# https://gist.github.com/michalmuskala/5ff53581b4b53adec2fff7fb4d69fd52
# Lives here because it literally broke memory measurements so it's always
# an interesting case to have around :)
defmodule BenchKeyword do
  @compile :inline_list_funcs

  def delete_v0(keywords, key) when is_list(keywords) and is_atom(key) do
    :lists.filter(fn {k, _} -> k != key end, keywords)
  end

  def delete_v1(keywords, key) when is_list(keywords) and is_atom(key) do
    do_delete(keywords, key, _deleted? = false)
  catch
    :not_deleted -> keywords
  end

  defp do_delete([{key, _} | rest], key, _deleted?),
    do: do_delete(rest, key, true)

  defp do_delete([{_, _} = pair | rest], key, deleted?),
    do: [pair | do_delete(rest, key, deleted?)]

  defp do_delete([], _key, _deleted? = true),
    do: []

  defp do_delete([], _key, _deleted? = false),
    do: throw(:not_deleted)

  def delete_v2(keywords, key) when is_list(keywords) and is_atom(key) do
    delete_v2_key(keywords, key, [])
  end

  defp delete_v2_key([{key, _} | tail], key, heads) do
    delete_v2_key(tail, key, heads)
  end

  defp delete_v2_key([{_, _} = pair | tail], key, heads) do
    delete_v2_key(tail, key, [pair | heads])
  end

  defp delete_v2_key([], _key, heads) do
    :lists.reverse(heads)
  end

  def delete_v3(keywords, key) when is_list(keywords) and is_atom(key) do
    case :lists.keymember(key, 1, keywords) do
      true -> delete_v3_key(keywords, key, [])
      _ -> keywords
    end
  end

  defp delete_v3_key([{key, _} | tail], key, heads) do
    delete_v3_key(tail, key, heads)
  end

  defp delete_v3_key([{_, _} = pair | tail], key, heads) do
    delete_v3_key(tail, key, [pair | heads])
  end

  defp delete_v3_key([], _key, heads) do
    :lists.reverse(heads)
  end

  def delete_v4(keywords, key) when is_list(keywords) and is_atom(key) do
    case :lists.keymember(key, 1, keywords) do
      true -> delete_v4_key(keywords, key)
      _ -> keywords
    end
  end

  defp delete_v4_key([{key, _} | tail], key) do
    delete_v4_key(tail, key)
  end

  defp delete_v4_key([{_, _} = pair | tail], key) do
    [pair | delete_v4_key(tail, key)]
  end

  defp delete_v4_key([], _key) do
    []
  end
end

benches = %{
  "delete old" => fn {kv, key} -> BenchKeyword.delete_v0(kv, key) end,
  "delete throw" => fn {kv, key} -> BenchKeyword.delete_v1(kv, key) end,
  "delete reverse" => fn {kv, key} -> BenchKeyword.delete_v2(kv, key) end,
  "delete keymember reverse" => fn {kv, key} -> BenchKeyword.delete_v3(kv, key) end,
  "delete keymember body" => fn {kv, key} -> BenchKeyword.delete_v4(kv, key) end
}

inputs = %{
  "small miss" => {Enum.map(1..10, &{:"k#{&1}", &1}), :k11},
  "small hit" => {Enum.map(1..10, &{:"k#{&1}", &1}), :k10},
  "large miss" => {Enum.map(1..100, &{:"k#{&1}", &1}), :k101},
  "large hit" => {Enum.map(1..100, &{:"k#{&1}", &1}), :k100},
  "huge miss" => {Enum.map(1..10000, &{:"k#{&1}", &1}), :k10001},
  "huge hit" => {Enum.map(1..10000, &{:"k#{&1}", &1}), :k10000}
}

Benchee.run(
  benches,
  inputs: inputs,
  print: [fast_warning: false],
  memory_time: 0.001,
  warmup: 1,
  time: 2
)

# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.8.1
# Erlang 21.3.2

# Benchmark suite executing with the following configuration:
# warmup: 1 s
# time: 2 s
# memory time: 1 ms
# parallel: 1
# inputs: huge hit, huge miss, large hit, large miss, small hit, small miss
# Estimated total run time: 1.50 min

# Benchmarking delete keymember body with input huge hit...
# Benchmarking delete keymember body with input huge miss...
# Benchmarking delete keymember body with input large hit...
# Benchmarking delete keymember body with input large miss...
# Benchmarking delete keymember body with input small hit...
# Benchmarking delete keymember body with input small miss...
# Benchmarking delete keymember reverse with input huge hit...
# Benchmarking delete keymember reverse with input huge miss...
# Benchmarking delete keymember reverse with input large hit...
# Benchmarking delete keymember reverse with input large miss...
# Benchmarking delete keymember reverse with input small hit...
# Benchmarking delete keymember reverse with input small miss...
# Benchmarking delete old with input huge hit...
# Benchmarking delete old with input huge miss...
# Benchmarking delete old with input large hit...
# Benchmarking delete old with input large miss...
# Benchmarking delete old with input small hit...
# Benchmarking delete old with input small miss...
# Benchmarking delete reverse with input huge hit...
# Benchmarking delete reverse with input huge miss...
# Benchmarking delete reverse with input large hit...
# Benchmarking delete reverse with input large miss...
# Benchmarking delete reverse with input small hit...
# Benchmarking delete reverse with input small miss...
# Benchmarking delete throw with input huge hit...
# Benchmarking delete throw with input huge miss...
# Benchmarking delete throw with input large hit...
# Benchmarking delete throw with input large miss...
# Benchmarking delete throw with input small hit...
# Benchmarking delete throw with input small miss...

# ##### With input huge hit #####
# Name                               ips        average  deviation         median         99th %
# delete throw                    9.89 K      101.09 μs    ±16.14%      101.95 μs      184.00 μs
# delete reverse                  9.84 K      101.58 μs     ±9.47%      102.35 μs      152.15 μs
# delete keymember body           7.30 K      137.07 μs     ±7.20%      139.78 μs      168.69 μs
# delete keymember reverse        7.07 K      141.36 μs    ±10.96%      139.84 μs      206.47 μs
# delete old                      3.63 K      275.31 μs    ±13.72%      286.14 μs      448.82 μs

# Comparison:
# delete throw                    9.89 K
# delete reverse                  9.84 K - 1.00x slower +0.49 μs
# delete keymember body           7.30 K - 1.36x slower +35.98 μs
# delete keymember reverse        7.07 K - 1.40x slower +40.27 μs
# delete old                      3.63 K - 2.72x slower +174.22 μs

# Memory usage statistics:

# Name                        Memory usage
# delete throw                   156.23 KB
# delete reverse                 195.94 KB - 1.25x memory usage +39.70 KB
# delete keymember body          156.23 KB - 1.00x memory usage +0 KB
# delete keymember reverse       195.94 KB - 1.25x memory usage +39.70 KB
# delete old                     156.29 KB - 1.00x memory usage +0.0547 KB

# **All measurements for memory usage were the same**

# ##### With input huge miss #####
# Name                               ips        average  deviation         median         99th %
# delete keymember body          28.07 K       35.62 μs     ±2.46%       35.52 μs       39.29 μs
# delete keymember reverse       27.49 K       36.38 μs    ±10.10%       35.50 μs       44.30 μs
# delete reverse                  9.66 K      103.49 μs    ±15.65%      102.55 μs      169.22 μs
# delete throw                    9.21 K      108.62 μs     ±9.04%      107.38 μs      129.44 μs
# delete old                      3.69 K      270.99 μs    ±11.01%      285.97 μs      354.03 μs

# Comparison:
# delete keymember body          28.07 K
# delete keymember reverse       27.49 K - 1.02x slower +0.76 μs
# delete reverse                  9.66 K - 2.91x slower +67.87 μs
# delete throw                    9.21 K - 3.05x slower +73.00 μs
# delete old                      3.69 K - 7.61x slower +235.37 μs

# Memory usage statistics:

# Name                        Memory usage
# delete keymember body                0 B
# delete keymember reverse             0 B - 1.00x memory usage +0 B
# delete reverse                  200640 B - ∞ x memory usage +200640 B
# delete throw                         0 B - 1.00x memory usage +0 B
# delete old                      160056 B - ∞ x memory usage +160056 B

# **All measurements for memory usage were the same**

# ##### With input large hit #####
# Name                               ips        average  deviation         median         99th %
# delete reverse               1003.02 K        1.00 μs  ±1747.60%        0.85 μs        1.64 μs
# delete throw                  977.16 K        1.02 μs  ±1359.29%        0.94 μs        1.51 μs
# delete keymember reverse      890.66 K        1.12 μs   ±971.77%        1.01 μs        1.80 μs
# delete keymember body         788.15 K        1.27 μs  ±1251.23%        1.12 μs        2.29 μs
# delete old                    373.54 K        2.68 μs   ±314.76%        2.48 μs        4.72 μs

# Comparison:
# delete reverse               1003.02 K
# delete throw                  977.16 K - 1.03x slower +0.0264 μs
# delete keymember reverse      890.66 K - 1.13x slower +0.126 μs
# delete keymember body         788.15 K - 1.27x slower +0.27 μs
# delete old                    373.54 K - 2.69x slower +1.68 μs

# Memory usage statistics:

# Name                        Memory usage
# delete reverse                   3.09 KB
# delete throw                     1.55 KB - 0.50x memory usage -1.54688 KB
# delete keymember reverse         3.09 KB - 1.00x memory usage +0 KB
# delete keymember body            1.55 KB - 0.50x memory usage -1.54688 KB
# delete old                       1.60 KB - 0.52x memory usage -1.49219 KB

# **All measurements for memory usage were the same**

# ##### With input large miss #####
# Name                               ips        average  deviation         median         99th %
# delete keymember reverse        4.50 M      222.31 ns  ±3901.16%         206 ns         363 ns
# delete keymember body           4.29 M      232.88 ns  ±3459.43%         206 ns         407 ns
# delete reverse                  1.01 M      989.61 ns  ±1552.26%         853 ns        1615 ns
# delete throw                    0.77 M     1299.03 ns  ±1347.05%        1175 ns        1834 ns
# delete old                      0.38 M     2631.93 ns   ±374.40%        2483 ns        4142 ns

# Comparison:
# delete keymember reverse        4.50 M
# delete keymember body           4.29 M - 1.05x slower +10.57 ns
# delete reverse                  1.01 M - 4.45x slower +767.31 ns
# delete throw                    0.77 M - 5.84x slower +1076.72 ns
# delete old                      0.38 M - 11.84x slower +2409.62 ns

# Memory usage statistics:

# Name                        Memory usage
# delete keymember reverse             0 B
# delete keymember body                0 B - 1.00x memory usage +0 B
# delete reverse                    3200 B - ∞ x memory usage +3200 B
# delete throw                         0 B - 1.00x memory usage +0 B
# delete old                        1656 B - ∞ x memory usage +1656 B

# **All measurements for memory usage were the same**

# ##### With input small hit #####
# Name                               ips        average  deviation         median         99th %
# delete reverse                  5.80 M      172.42 ns  ±9750.41%         111 ns         274 ns
# delete throw                    5.06 M      197.49 ns ±11517.56%         111 ns         294 ns
# delete keymember reverse        4.73 M      211.61 ns  ±9126.78%         142 ns         333 ns
# delete keymember body           4.39 M      227.67 ns ±10271.09%         137 ns         340 ns
# delete old                      2.44 M      410.04 ns  ±4592.82%         313 ns         575 ns

# Comparison:
# delete reverse                  5.80 M
# delete throw                    5.06 M - 1.15x slower +25.07 ns
# delete keymember reverse        4.73 M - 1.23x slower +39.19 ns
# delete keymember body           4.39 M - 1.32x slower +55.26 ns
# delete old                      2.44 M - 2.38x slower +237.63 ns

# Memory usage statistics:

# Name                        Memory usage
# delete reverse                     288 B
# delete throw                       144 B - 0.50x memory usage -144 B
# delete keymember reverse           288 B - 1.00x memory usage +0 B
# delete keymember body              144 B - 0.50x memory usage -144 B
# delete old                         200 B - 0.69x memory usage -88 B

# **All measurements for memory usage were the same**

# ##### With input small miss #####
# Name                               ips        average  deviation         median         99th %
# delete keymember body          15.60 M       64.10 ns ±20187.61%          45 ns         126 ns
# delete keymember reverse       14.74 M       67.85 ns ±20395.85%          46 ns         140 ns
# delete reverse                  5.55 M      180.02 ns ±11840.78%         114 ns         356 ns
# delete throw                    3.37 M      297.09 ns  ±7734.98%         202 ns         463 ns
# delete old                      2.49 M      400.87 ns  ±4818.94%         308 ns         624 ns

# Comparison:
# delete keymember body          15.60 M
# delete keymember reverse       14.74 M - 1.06x slower +3.74 ns
# delete reverse                  5.55 M - 2.81x slower +115.92 ns
# delete throw                    3.37 M - 4.63x slower +232.99 ns
# delete old                      2.49 M - 6.25x slower +336.77 ns

# Memory usage statistics:

# Name                        Memory usage
# delete keymember body                0 B
# delete keymember reverse             0 B - 1.00x memory usage +0 B
# delete reverse                     320 B - ∞ x memory usage +320 B
# delete throw                         0 B - 1.00x memory usage +0 B
# delete old                         216 B - ∞ x memory usage +216 B

# **All measurements for memory usage were the same**
