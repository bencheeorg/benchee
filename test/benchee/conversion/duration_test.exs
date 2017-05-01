defmodule Benchee.Conversion.DurationTest do
  use ExUnit.Case, async: true
  import Benchee.Conversion.Duration
  doctest Benchee.Conversion.Duration

  describe ".format" do
    test ".format(98.7654321)" do
      assert format(98.7654321) == "98.77 μs"
    end

    test ".format(987.654321)" do
      assert format(987.654321) == "987.65 μs"
    end

    test ".format(9_876.54321)" do
      assert format(9_876.54321) == "9.88 ms"
    end

    test ".format(98_765.4321)" do
      assert format(98_765.4321) == "98.77 ms"
    end

    test ".format(987_654.321)" do
      assert format(987_654.321) == "987.65 ms"
    end

    test ".format(9_876_543.21)" do
      assert format(9_876_543.21) == "9.88 s"
    end

    test ".format(98_765_432.19)" do
      assert format(98_765_432.19) == "1.65 min"
    end

    test ".format(987_654_321.9876)" do
      assert format(987_654_321.9876) == "16.46 min"
    end

    test ".format(9_876_543_219.8765)" do
      assert format(9_876_543_219.8765) == "2.74 h"
    end

    test ".format(0)" do
      assert format(0) == "0.0 μs"
    end
  end

  @list_with_mostly_milliseconds [1, 200, 3_000, 4_000, 500_000, 6_000_000, 77_000_000_000]

  describe ".best" do
    test "when list is mostly milliseconds" do
      assert best(@list_with_mostly_milliseconds) == unit_for(:millisecond)
    end

    test "when list is mostly milliseconds, strategy: :smallest" do
      assert best(@list_with_mostly_milliseconds, strategy: :smallest) == unit_for(:microsecond)
    end

    test "when list is mostly milliseconds, strategy: :largest" do
      assert best(@list_with_mostly_milliseconds, strategy: :largest) == unit_for(:hour)
    end

    test "when list is mostly milliseconds, strategy: :none" do
      assert best(@list_with_mostly_milliseconds, strategy: :none) == unit_for(:microsecond)
    end
  end
end
