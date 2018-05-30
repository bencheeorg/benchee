defmodule Benchee.Utility.RepeatNTest do
  use ExUnit.Case, async: true
  import Benchee.Utility.RepeatN

  test "calls it n times" do
    assert_called_n(10)
  end

  test "calls it only one time when 1 is specified" do
    assert_called_n(1)
  end

  test "calls it 0 times when 0 is specified" do
    assert_called_n(0)
  end

  defp assert_called_n(n) do
    repeat_n(fn -> send(self(), :called) end, n)

    assert_called_exactly_times(n)
  end

  defp assert_called_exactly_times(n) when n <= 0 do
    refute_receive :called
  end

  defp assert_called_exactly_times(n) do
    Enum.each(Enum.to_list(1..n), fn _ -> assert_receive :called end)
  end
end
