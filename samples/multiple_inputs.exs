map_fun = fn i -> [i, i * i] end

Benchee.run(
  %{
    "flat_map" => fn input -> Enum.flat_map(input, map_fun) end,
    "map.flatten" => fn input -> input |> Enum.map(map_fun) |> List.flatten() end
  },
  inputs: %{
    "Small" => Enum.to_list(1..1000),
    "Bigger" => Enum.to_list(1..100_000)
  }
)

# tobi@speedy ~/github/benchee $ time mix run samples/multiple_inputs.exs
# Erlang/OTP 19 [erts-8.1] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]
# Elixir 1.3.4
# Benchmark suite executing with the following configuration:
# warmup: 2.0s
# time: 5.0s
# parallel: 1
# inputs: Bigger, Small
# Estimated total run time: 28.0s
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
# map.flatten        139.35        7.18 ms     ±8.86%        7.06 ms
# flat_map            70.91       14.10 ms    ±18.04%       14.37 ms
#
# Comparison:
# map.flatten        139.35
# flat_map            70.91 - 1.97x slower
#
# ##### With input Small #####
# Name                  ips        average  deviation         median
# map.flatten       18.14 K       55.13 μs     ±9.31%          54 μs
# flat_map          10.65 K       93.91 μs     ±8.70%          94 μs
#
# Comparison:
# map.flatten       18.14 K
# flat_map          10.65 K - 1.70x slower
#
# real	0m28.434s
# user	0m27.032s
# sys	0m1.424s
