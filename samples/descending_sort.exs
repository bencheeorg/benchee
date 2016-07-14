list  = 1..10_000 |> Enum.to_list |> Enum.shuffle

Benchee.run %{
  "sort |> reverse"  => fn -> list |> Enum.sort |> Enum.reverse  end,
  "sort(fun)"        => fn -> Enum.sort(list, &(&1 > &2)) end,
  "sort_by(-value)"  => fn -> Enum.sort_by(list, fn(val) -> -val end) end}
