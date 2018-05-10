defmodule Benchee.Conversion.DurationTest do
  use ExUnit.Case, async: true
  import Benchee.Conversion.Duration
  doctest Benchee.Conversion.Duration

  describe ".format" do
    test ".format(98.7654321)" do
      assert format(98.7654321) == "98.77 ns"
    end

    test ".format(987.654321)" do
      assert format(987.654321) == "987.65 ns"
    end

    test ".format(9_876.54321)" do
      assert format(9_876.54321) == "9.88 μs"
    end

    test ".format(98_765.4321)" do
      assert format(98_765.4321) == "98.77 μs"
    end

    test ".format(987_654.321)" do
      assert format(987_654.321) == "987.65 μs"
    end

    test ".format(9_876_543210)" do
      assert format(9_876_543_210) == "9.88 s"
    end

    test ".format(98_765_432190)" do
      assert format(98_765_432_190) == "1.65 min"
    end

    test ".format(987_654_321987.6)" do
      assert format(987_654_321_987.6) == "16.46 min"
    end

    test ".format(9_876_543_219876.5)" do
      assert format(9_876_543_219_876.5) == "2.74 h"
    end

    test ".format(523.0)" do
      assert format(523.0) == "523 ns"
    end

    test ".format(0)" do
      assert format(0) == "0 ns"
    end
  end

  @list_with_mostly_microseconds [1, 200, 3_000, 4_000, 500_000, 6_000_000, 7_777_000_000_000]

  describe ".best" do
    test "when list is mostly microseconds" do
      assert best(@list_with_mostly_microseconds) == unit_for(:microsecond)
    end

    test "when list is mostly microseconds, strategy: :smallest" do
      assert best(@list_with_mostly_microseconds, strategy: :smallest) == unit_for(:nanosecond)
    end

    test "when list is mostly microseconds, strategy: :largest" do
      assert best(@list_with_mostly_microseconds, strategy: :largest) == unit_for(:hour)
    end

    test "when list is mostly microseconds, strategy: :none" do
      assert best(@list_with_mostly_microseconds, strategy: :none) == unit_for(:nanosecond)
    end
  end
end
