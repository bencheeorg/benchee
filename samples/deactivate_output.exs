# Deactivate the fast warnings if they annoy you
# You can also deactivate the comparison report
Benchee.run(
  %{
    "fast" => fn -> 1 + 1 end,
    "also" => fn -> 20 * 20 end
  },
  time: 2,
  warmup: 1,
  print: [
    benchmarking: false,
    configuration: false,
    fast_warning: false
  ],
  console: [
    comparison: false
  ]
)

# tobi@speedy ~/github/benchee $ mix run samples/deactivate_output.exs
#
# Name           ips        average  deviation         median
# fast       88.43 M      0.0113 μs    ±64.63%      0.0110 μs
# also       87.23 M      0.0115 μs    ±57.19%      0.0110 μs
