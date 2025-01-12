defmodule Benchee.Collect.ReductionsTest do
  use ExUnit.Case, async: true
  alias Benchee.Benchmark.Collect.Reductions

  describe "collect/1" do
    test "returns the reduction count and result of the function" do
      assert {reductions, [1, 2, 3, 4, 5, 6, 7, 8, 9]} =
               Reductions.collect(fn -> Enum.to_list(1..9) end)

      # it seems that the JIT may interfere here with the values as we get flakyness
      # on higher OTP versions and so we're loosening up the boundaries here, sadly
      assert reductions >= 13
      assert reductions <= 250

      assert {reductions, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]} =
               Reductions.collect(fn -> Enum.to_list(1..10) end)

      assert reductions >= 14
      assert reductions <= 250

      assert {reductions, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]} =
               Reductions.collect(fn -> Enum.to_list(1..11) end)

      assert reductions >= 14
      assert reductions <= 250
    end
  end
end
