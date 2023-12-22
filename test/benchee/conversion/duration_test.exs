defmodule Benchee.Conversion.DurationTest do
  use ExUnit.Case, async: true
  import Benchee.Conversion.Duration
  doctest Benchee.Conversion.Duration, import: true

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

    test ".format(9_876_543_210)" do
      assert format(9_876_543_210) == "9.88 s"
    end

    test ".format(98_765_432_190)" do
      assert format(98_765_432_190) == "1.65 min"
    end

    test ".format(987_654_321_987.6)" do
      assert format(987_654_321_987.6) == "16.46 min"
    end

    test ".format(9_876_543_219_876.5)" do
      assert format(9_876_543_219_876.5) == "2.74 h"
    end

    test ".format(523.0)" do
      assert format(523.0) == "523 ns"
    end

    test ".format(0)" do
      assert format(0) == "0 ns"
    end
  end

  describe ".format_human" do
    test ".format_human(0)" do
      assert format_human(0) == "0 ns"
    end

    test ".format_human(0.00)" do
      assert format_human(0.00) == "0 ns"
    end

    test ".format_human(98.7654321)" do
      assert format_human(98.7654321) == "98.77 ns"
    end

    test ".format_human(523.0)" do
      assert format_human(523.0) == "523 ns"
    end

    test ".format_human(987.654321)" do
      assert format_human(987.654321) == "987.65 ns"
    end

    test ".format_human(9_008)" do
      assert format_human(9_008) == "9 μs 8 ns"
    end

    # particularly nasty bug
    test ".format_human()" do
      assert format_human(2_000_000_000.0) == "2 s"
    end

    test ".format_human(9_876.54321)" do
      assert format_human(9_876.54321) == "9 μs 876.54 ns"
    end

    test ".format_human(98_765.4321)" do
      assert format_human(98_765.4321) == "98 μs 765.43 ns"
    end

    test ".format_human(987_654.321)" do
      assert format_human(987_654.321) == "987 μs 654.32 ns"
    end

    test ".format_human(9_008_000_000)" do
      assert format_human(9_008_000_000) == "9 s 8 ms"
    end

    test ".format_human(9_876_543_210)" do
      assert format_human(9_876_543_210) == "9 s 876 ms 543 μs 210 ns"
    end

    test ".format_human(90_000_000_000)" do
      assert format_human(90_000_000_000) == "1 min 30 s"
    end

    test ".format_human(98_765_432_190)" do
      assert format_human(98_765_432_190) == "1 min 38 s 765 ms 432 μs 190 ns"
    end

    test ".format_human(987_654_321_987.6)" do
      assert format_human(987_654_321_987.6) == "16 min 27 s 654 ms 321 μs 987.60 ns"
    end

    test ".format_human(3_900_000_000_000)" do
      assert format_human(3_900_000_000_000) == "1 h 5 min"
    end

    test ".format_human(9_876_543_219_876.5)" do
      assert format_human(9_876_543_219_876.5) == "2 h 44 min 36 s 543 ms 219 μs 876.50 ns"
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
