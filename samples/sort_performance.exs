list_10k  = 1..10_000 |> Enum.to_list |> Enum.shuffle
list_100k = 1..100_000 |> Enum.to_list |> Enum.shuffle

Benchee.run [{"10k",  fn -> Enum.sort(list_10k) end},
             {"100k", fn -> Enum.sort(list_100k) end}]
