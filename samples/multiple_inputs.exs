Benchee.run(%{
  inputs: %{
    "Small" => Enum.to_list(1..1000),
    "Bigger" => Enum.to_list(1..100_000)
    }
  },
  %{
  "flat_map"    => fn(input) -> Enum.flat_map(input, map_fun) end,
  "map.flatten" => fn(input) -> input |> Enum.map(map_fun) |> List.flatten end
})

# tobi@speedy ~/github/benchee $ mix run samples/multiple_inputs.exs
# Erlang/OTP 19 [erts-8.1] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]
# Elixir 1.3.4
# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 5.0s
# parallel: 1
# Estimated total run time: 14.0s
#
#
# Benchmarking with input Bigger:
# Benchmarking flat_map...
# Benchmarking map.flatten...
#
# Benchmarking with input Small:
# Benchmarking flat_map...
# Benchmarking map.flatten...
#
# ##### With input Bigger #####
# Name                  ips        average  deviation         median
# map.flatten        139.57        7.17 ms     ±7.60%        7.06 ms
# flat_map            82.34       12.14 ms     ±7.28%       12.60 ms
#
# Comparison:
# map.flatten        139.57
# flat_map            82.34 - 1.69x slower
#
# ##### With input Small #####
# Name                  ips        average  deviation         median
# map.flatten       17.78 K       56.23 μs    ±24.71%       54.00 μs
# flat_map          10.51 K       95.17 μs    ±11.80%       94.00 μs
#
# Comparison:
# map.flatten       17.78 K
# flat_map          10.51 K - 1.69x slower
