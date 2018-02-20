defmodule Benchee.MemoryMeasureTest do
  use ExUnit.Case, async: true
  alias Benchee.MemoryMeasure

  describe "apply/1" do
    test "returns the result of the function and the memory used (in bytes)" do
      fun_to_run = fn -> Enum.to_list(1..10) end
      assert {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10], memory_used} = MemoryMeasure.apply(fun_to_run)
      assert memory_used > 350
      assert memory_used < 380
    end
  end

  describe "apply/3" do
    test "returns the result of the function and the memory used (in bytes)" do
      assert {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10], memory_used} =
               MemoryMeasure.apply(Enum, :to_list, [1..10])

      assert memory_used > 350
      assert memory_used < 380
    end
  end
end
