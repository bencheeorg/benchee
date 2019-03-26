n = 1_000
range = 1..n
list = Enum.to_list(range)
fun = fn -> 0 end

Benchee.run(%{
  "Enum.each (range)" => fn -> Enum.each(range, fn _ -> fun.() end) end,
  "List comprehension (range)" => fn -> for _ <- range, do: fun.() end,
  "Enum.each (list)" => fn -> Enum.each(list, fn _ -> fun.() end) end,
  "List comprehension (list)" => fn -> for _ <- list, do: fun.() end,
  "Recursion" => fn -> Benchee.Utility.RepeatN.repeat_n(fun, n) end
})

# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.8.1
# Erlang 21.3.2

# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 5 s
# memory time: 0 ns
# parallel: 1
# inputs: none specified
# Estimated total run time: 35 s

# Benchmarking Enum.each (list)...
# Benchmarking Enum.each (range)...
# Benchmarking List comprehension (list)...
# Benchmarking List comprehension (range)...
# Benchmarking Recursion...

# Name                                 ips        average  deviation         median         99th %
# Recursion                        80.33 K       12.45 μs    ±12.46%       12.37 μs       15.02 μs
# Enum.each (list)                 45.83 K       21.82 μs    ±19.54%       20.57 μs       34.33 μs
# List comprehension (list)        43.23 K       23.13 μs    ±12.07%       22.72 μs       33.55 μs
# List comprehension (range)       35.26 K       28.36 μs    ±10.99%       27.88 μs       36.29 μs
# Enum.each (range)                30.09 K       33.24 μs    ±11.21%       32.83 μs       48.55 μs

# Comparison:
# Recursion                        80.33 K
# Enum.each (list)                 45.83 K - 1.75x slower +9.37 μs
# List comprehension (list)        43.23 K - 1.86x slower +10.69 μs
# List comprehension (range)       35.26 K - 2.28x slower +15.91 μs
# Enum.each (range)                30.09 K - 2.67x slower +20.79 μs
