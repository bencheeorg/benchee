Benchee.run(%{time: 3},
             [{"My Benchmark", fn -> Enum.to_list(1..10_000) end},
              {"My other benchmrk", fn -> Enum.to_list(1..100_000) end}])
