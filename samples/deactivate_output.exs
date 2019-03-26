# Deactivate the fast warnings if they annoy you
# You can also deactivate the comparison report
Benchee.run(
  %{
    "something" => fn -> Enum.map([1, 2, 3], fn i -> i * i end) end
  },
  time: 2,
  warmup: 1,
  print: [
    benchmarking: false,
    configuration: false,
    fast_warning: false
  ],
  formatters: [{Benchee.Formatters.Console, comparison: false}]
)

# Name                ips        average  deviation         median         99th %
# something        6.62 M      151.08 ns ±11000.02%         100 ns         253 ns
