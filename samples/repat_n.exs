n = 1_000
range = 1..n
list  = Enum.to_list range
fun   = fn -> 0 end

Benchee.run %{
  "Enum.each (range)" => fn -> Enum.each(range, fn(_) -> fun.() end) end,
  "List comprehension (range)" => fn -> for _ <- range, do: fun.() end,
  "Enum.each (list)" => fn -> Enum.each(list, fn(_) -> fun.() end) end,
  "List comprehension (list)" => fn -> for _ <- list, do: fun.() end,
  "Recursion" => fn -> Benchee.Utility.RepeatN.repeat_n(fun, n) end
}

# tobi@happy ~/github/benchee $ mix run samples/repat_n.exs
# Erlang/OTP 19 [erts-8.1] [source-4cc2ce3] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]
# Elixir 1.3.4
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
# Name                                 ips        average  deviation         median
# Recursion                        90.60 K       11.04 μs     ±8.72%       11 μs
# Enum.each (list)                 50.41 K       19.84 μs    ±20.27%       20 μs
# List comprehension (list)        44.60 K       22.42 μs    ±13.40%       22 μs
# List comprehension (range)       20.73 K       48.24 μs     ±8.69%       47 μs
# Enum.each (range)                19.94 K       50.14 μs     ±6.42%       50 μs
#
# Comparison:
# Recursion                        90.60 K
# Enum.each (list)                 50.41 K - 1.80x slower
# List comprehension (list)        44.60 K - 2.03x slower
# List comprehension (range)       20.73 K - 4.37x slower
# Enum.each (range)                19.94 K - 4.54x slower
