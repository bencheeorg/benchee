IO.puts "Not compiled..."

Benchee.run(%{
  "Integer addition"          => fn -> 1 + 1 end,
  "String concatention"       => fn -> "1" <> "1" end,
  "noop"                      => fn -> 0 end,
}, time: 3)

IO.puts "\ncompiled..."

defmodule Benchmark do
  def benchmark do
    Benchee.run(%{
      "Integer addition"          => fn -> 1 + 1 end,
      "String concatention"       => fn -> "1" <> "1" end,
      "noop"                      => fn -> 0 end,
    }, time: 3)
  end
end

Benchmark.benchmark()

# Difference seems somwhat marginal even for very small funs
#
# tobi@speedy ~/github/benchee $ mix run samples/fast_compile_no_compile.exs
# Not compiled...
# Elixir 1.4.2
# Erlang 19.2
# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 3 s
# parallel: 1
# inputs: none specified
# Estimated total run time: 15 s
#
# ...
#
# Name                          ips        average  deviation         median
# noop                      86.72 M      0.0115 μs    ±46.47%      0.0110 μs
# Integer addition          86.53 M      0.0116 μs    ±45.04%      0.0110 μs
# String concatention       86.34 M      0.0116 μs    ±43.92%      0.0110 μs
#
# Comparison:
# noop                      86.72 M
# Integer addition          86.53 M - 1.00x slower
# String concatention       86.34 M - 1.00x slower
#
# compiled...
# Elixir 1.4.2
# Erlang 19.2
# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 3 s
# parallel: 1
# inputs: none specified
# Estimated total run time: 15 s
#
# ...
#
# Name                          ips        average  deviation         median
# noop                      87.87 M      0.0114 μs    ±45.20%      0.0110 μs
# String concatention       87.47 M      0.0114 μs    ±48.58%      0.0110 μs
# Integer addition          87.34 M      0.0114 μs    ±47.71%      0.0110 μs
#
# Comparison:
# noop                      87.87 M
# String concatention       87.47 M - 1.00x slower
# Integer addition          87.34 M - 1.01x slower
