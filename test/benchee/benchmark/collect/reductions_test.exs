defmodule Benchee.Collect.ReductionsTest do
  use ExUnit.Case, async: true
  alias Benchee.Benchmark.Collect.Reductions

  describe "collect/1" do
    test "returns the reduction count and result of the function" do
      assert {32, [1, 2, 3, 4, 5, 6, 7, 8, 9]} =
               Reductions.collect(fn -> Enum.to_list(1..9) end)

      assert {35, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]} =
               Reductions.collect(fn -> Enum.to_list(1..10) end)

      assert {38, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]} =
               Reductions.collect(fn -> Enum.to_list(1..11) end)
    end
  end
end
