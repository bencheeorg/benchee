Benchee.run(%{time: 3},
             [{"Integer addition",          fn -> 1 + 1 end},
              {"Console concatention",      fn -> "1" <> "1" end},
              {"adding a head to an array", fn -> [1 | [1]] end},
              {"++ array concat",           fn -> [1] ++ [1] end}])
