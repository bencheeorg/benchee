n = 1_000
range = Enum.to_list 1..n
fun   = fn -> 0 end

defmodule RepeatN do
  def repeat_n(1, function) do
    function.()
  end

  def repeat_n(count, function) do
    function.()
    repeat_n(count - 1, function)
  end
end

Benchee.run [{"Enum.each", fn -> Enum.each(range, fn(_) -> fun.() end) end},
             {"List comprehension", fn -> for _ <- range, do: fun.() end},
             {"Recursion", fn -> RepeatN.repeat_n(n, fun) end}]
