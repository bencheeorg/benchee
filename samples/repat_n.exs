n = 1_000
range = 1..n
list  = Enum.to_list range
fun   = fn -> 0 end

Benchee.run [{"Enum.each (range)",
              fn -> Enum.each(range, fn(_) -> fun.() end) end},
             {"List comprehension (range)",
              fn -> for _ <- range, do: fun.() end},
             {"Enum.each (list)",
              fn -> Enum.each(list, fn(_) -> fun.() end) end},
             {"List comprehension (list)", fn -> for _ <- list, do: fun.() end},
             {"Recursion", fn -> Benchee.RepeatN.repeat_n(fun, n) end}]

# tobi@happy ~/github/benchee $ mix run samples/repat_n.exs 
# Benchmarking Enum.each (range)...
# Benchmarking List comprehension (range)...
# Benchmarking Enum.each (list)...
# Benchmarking List comprehension (list)...
# Benchmarking Recursion...
#
# Name                          ips            average        deviation      median
# Recursion                     83119.95       12.03μs        (±4.94%)       12.00μs
# Enum.each (list)              56319.23       17.76μs        (±26.27%)      18.00μs
# List comprehension (list)     47555.65       21.03μs        (±23.10%)      21.00μs
# List comprehension (range)    20138.52       49.66μs        (±9.56%)       49.00μs
# Enum.each (range)             20041.01       49.90μs        (±9.90%)       49.00μs
#
# Comparison:
# Recursion                     83119.95
# Enum.each (list)              56319.23        - 1.48x slower
# List comprehension (list)     47555.65        - 1.75x slower
# List comprehension (range)    20138.52        - 4.13x slower
# Enum.each (range)             20041.01        - 4.15x slower
#
