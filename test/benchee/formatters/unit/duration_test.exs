defmodule Benchee.Unit.DurationTest do
  use ExUnit.Case
  import Benchee.Unit.Duration
  doctest Benchee.Unit.Duration

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
    assert format(98_765_432.19) == "1.65 m"
  end

  test ".format(987_654_321.9876)" do
    assert format(987_654_321.9876) == "16.46 m"
  end

  test ".format(9_876_543_219.8765)" do
    assert format(9_876_543_219.8765) == "2.74 h"
  end

  @list_with_mostly_milliseconds [1, 200, 3_000, 4_000, 500_000, 6_000_000, 77_000_000_000]

  test ".best when list is mostly milliseconds" do
    assert best(@list_with_mostly_milliseconds) == :millisecond
  end

  test ".best when list is mostly milliseconds, strategy: :smallest" do
    assert best(@list_with_mostly_milliseconds, strategy: :smallest) == :microsecond
  end

  test ".best when list is mostly milliseconds, strategy: :largest" do
    assert best(@list_with_mostly_milliseconds, strategy: :largest) == :hour
  end

  test ".best when list is mostly milliseconds, strategy: :base" do
    assert best(@list_with_mostly_milliseconds, strategy: :base) == :microsecond
  end
end
