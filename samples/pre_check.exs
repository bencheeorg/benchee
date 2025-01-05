a = 7

Benchee.run(%{"a*2" => fn -> a * 2 end, "a+a" => fn -> a + a end},
  time: 0,
  warmup: 0,
  pre_check: true
)

Benchee.run(%{"a*2" => fn -> a * 2 end, "a+a" => fn -> a + a end},
  time: 0,
  warmup: 0,
  pre_check: :all_same
)

Benchee.run(%{"a*2" => fn -> a * 2 end, "a+a" => fn -> a + a + 1 end},
  time: 0,
  warmup: 0,
  pre_check: :all_same
)
