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
# Recursion                       89641.19        11.16μs    (±22.51%)        11.00μs
# Enum.each (list)                49061.60        20.38μs    (±21.32%)        20.00μs
# List comprehension (list)       44405.33        22.52μs    (±30.45%)        22.00μs
# List comprehension (range)      20914.16        47.81μs    (±11.76%)        47.00μs
# Enum.each (range)               19924.18        50.19μs     (±4.12%)        50.00μs
#
# Comparison:
# Recursion                       89641.19
# Enum.each (list)                49061.60 - 1.83x slower
# List comprehension (list)       44405.33 - 2.02x slower
# List comprehension (range)      20914.16 - 4.29x slower
# Enum.each (range)               19924.18 - 4.50x slower
