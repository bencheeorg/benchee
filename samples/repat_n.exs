n = 1_000
range = 1..n
list  = Enum.to_list range
fun   = fn -> 0 end

Benchee.run %{
  "Enum.each (range)" => fn -> Enum.each(range, fn(_) -> fun.() end) end,
  "List comprehension (range)" => fn -> for _ <- range, do: fun.() end,
  "Enum.each (list)" => fn -> Enum.each(list, fn(_) -> fun.() end) end,
  "List comprehension (list)" => fn -> for _ <- list, do: fun.() end,
  "Recursion" => fn -> Benchee.RepeatN.repeat_n(fun, n) end
}

# tobi@happy ~/github/benchee $ mix run samples/repat_n.exs
# Erlang/OTP 19 [erts-8.0] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]
# Elixir 1.3.2
# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 5.0s
# parallel: 1
# Estimated total run time: 35.0s
#
# Benchmarking Enum.each (list)...
# Benchmarking Enum.each (range)...
# Benchmarking List comprehension (list)...
# Benchmarking List comprehension (range)...
# Benchmarking Recursion...
#
# Name                                 ips        average    deviation         median
# Recursion                       68829.80       14.53 μs    (±15.57%)       14.00 μs
# Enum.each (list)                40328.88       24.80 μs    (±25.80%)       24.00 μs
# List comprehension (list)       34124.09       29.30 μs    (±16.76%)       28.00 μs
# List comprehension (range)      16241.21       61.57 μs    (±11.46%)       60.00 μs
# Enum.each (range)               15143.96       66.03 μs    (±11.82%)       64.00 μs
#
# Comparison:
# Recursion                       68829.80
# Enum.each (list)                40328.88 - 1.71x slower
# List comprehension (list)       34124.09 - 2.02x slower
# List comprehension (range)      16241.21 - 4.24x slower
# Enum.each (range)               15143.96 - 4.55x slower
