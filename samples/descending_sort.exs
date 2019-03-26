list = 1..10_000 |> Enum.to_list() |> Enum.shuffle()

Benchee.run(%{
  "sort |> reverse" => fn -> list |> Enum.sort() |> Enum.reverse() end,
  "sort(fun)" => fn -> Enum.sort(list, &(&1 > &2)) end,
  "sort_by(-value)" => fn -> Enum.sort_by(list, fn val -> -val end) end
})

# Operating System: Linux
# CPU Information: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
# Number of Available Cores: 8
# Available memory: 15.61 GB
# Elixir 1.8.1
# Erlang 21.2.7

# Benchmark suite executing with the following configuration:
# warmup: 2 s
# time: 5 s
# memory time: 0 ns
# parallel: 1
# inputs: none specified
# Estimated total run time: 21 s

# Benchmarking sort |> reverse...
# Benchmarking sort(fun)...
# Benchmarking sort_by(-value)...

# Name                      ips        average  deviation         median         99th %
# sort |> reverse        719.44        1.39 ms     ±8.83%        1.35 ms        1.94 ms
# sort(fun)              322.91        3.10 ms     ±6.55%        3.06 ms        4.21 ms
# sort_by(-value)        184.07        5.43 ms     ±6.81%        5.34 ms        6.49 ms

# Comparison:
# sort |> reverse        719.44
# sort(fun)              322.91 - 2.23x slower +1.71 ms
# sort_by(-value)        184.07 - 3.91x slower +4.04 ms
