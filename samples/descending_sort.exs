list  = 1..10_000 |> Enum.to_list |> Enum.shuffle

Benchee.run %{
  "sort |> reverse"  => fn -> list |> Enum.sort |> Enum.reverse  end,
  "sort(fun)"        => fn -> Enum.sort(list, &(&1 > &2)) end,
  "sort_by(-value)"  => fn -> Enum.sort_by(list, fn(val) -> -val end) end}

# tobi@airship ~/github/benchee $ mix run samples/descending_sort.exs
# Erlang/OTP 19 [erts-8.1] [source-4cc2ce3] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]
# Elixir 1.3.4
# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 5.0s
# parallel: 1
# Estimated total run time: 21.0s
#
# Benchmarking sort |> reverse...
# Benchmarking sort(fun)...
# Benchmarking sort_by(-value)...
#
# Name                      ips        average  deviation         median
# sort |> reverse        706.70        1.42 ms     ±8.67%        1.41 ms
# sort(fun)              284.06        3.52 ms     ±5.63%        3.38 ms
# sort_by(-value)        173.11        5.78 ms     ±3.27%        5.80 ms
#
# Comparison:
# sort |> reverse        706.70
# sort(fun)              284.06 - 2.49x slower
# sort_by(-value)        173.11 - 4.08x slower
