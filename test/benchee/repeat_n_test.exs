defmodule Benchee.RepeatNTest do
  use ExUnit.Case, async: true
  import Benchee.RepeatN
  import ExUnit.CaptureIO

  test "calls it n times" do
    assert_called_n 10
  end

  test "calls it only one time when 1 is specified" do
    assert_called_n 1
  end

  test "calls it 0 times when 0 is specified" do
    assert_called_n 0
  end

  defp assert_called_n(n) do
    output = capture_io fn ->
      repeat_n(fn -> IO.write "1" end, n)
    end

    assert times_called(output) == n
  end

  defp times_called(output) do
    String.length output
  end
end
