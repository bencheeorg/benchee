n = 1_000
range = Enum.to_list 1..n
fun   = fn -> 0 end

Benchee.run [{"Enum.each", fn -> Enum.each(range, fn(_) -> fun.() end) end},
             {"List comprehension", fn -> for _ <- range, do: fun.() end},
             {"Recursion", fn -> Benchee.RepeatN.repeat_n(fun, n) end}]
