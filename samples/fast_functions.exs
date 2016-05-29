Benchee.run(%{time: 3},
             [{"Integer addition", fn -> 1 + 1 end},
              {"String concatention", fn -> "1" <> "1" end},
              {"adding a head to ann array", fn -> [1 | [1]] end},
              {"++ array concat", fn -> [1] ++ [1] end}])
