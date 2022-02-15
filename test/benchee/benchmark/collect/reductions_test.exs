defmodule Benchee.Collect.ReductionsTest do
  use ExUnit.Case, async: true
  alias Benchee.Benchmark.Collect.Reductions

  describe "collect/1" do
    test "returns the reduction count and result of the function" do
      assert {reductions, [1, 2, 3, 4, 5, 6, 7, 8, 9]} =
               Reductions.collect(fn -> Enum.to_list(1..9) end)

      assert reductions >= 24
      assert reductions <= 58

      assert {reductions, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]} =
               Reductions.collect(fn -> Enum.to_list(1..10) end)

      assert reductions >= 26
      assert reductions <= 61

      assert {reductions, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]} =
               Reductions.collect(fn -> Enum.to_list(1..11) end)

      assert reductions >= 28
      assert reductions <= 64
    end
  end
end
