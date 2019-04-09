# random by design so that we get some memory statistics
Benchee.run(
  %{
    "Enum.to_list" => fn range -> Enum.to_list(range) end,
    "Enum.into" => fn range -> Enum.into(range, []) end
  },
  # formatters: [{Benchee.Formatters.Console, extended_statistics: true}],
  before_each: fn _ -> 0..(:rand.uniform(1_000) + 1000) end,
  warmup: 0.1,
  time: 0.1,
  memory_time: 1
)
