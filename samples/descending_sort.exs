list  = 1..10_000 |> Enum.to_list |> Enum.shuffle

Benchee.run %{
  "sort |> reverse"  => fn -> list |> Enum.sort |> Enum.reverse  end,
  "sort(fun)"        => fn -> Enum.sort(list, &(&1 > &2)) end,
  "sort_by(-value)"  => fn -> Enum.sort_by(list, fn(val) -> -val end) end}

# tobi@airship ~/github/benchee $ mix run samples/descending_sort.exs
# Erlang/OTP 19 [erts-8.0] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]
# Elixir 1.3.2
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
# Name                      ips        average    deviation         median
# sort |> reverse        587.92     1700.91 μs     (±6.39%)     1671.00 μs
# sort(fun)              229.59     4355.65 μs     (±3.20%)     4321.00 μs
# sort_by(-value)        146.59     6821.76 μs     (±4.18%)     6724.00 μs
#
# Comparison:
# sort |> reverse        587.92
# sort(fun)              229.59 - 2.56x slower
# sort_by(-value)        146.59 - 4.01x slower
