defmodule Benchee.Unit.DurationTest do
  use ExUnit.Case
  import Benchee.Unit.Duration
  doctest Benchee.Unit.Duration

  test ".format(98.7654321)" do
    assert format(98.7654321) == "98.77μs"
  end

  test ".format(987.654321)" do
    assert format(987.654321) == "987.65μs"
  end

  test ".format(9_876.54321)" do
    assert format(9_876.54321) == "9.88ms"
  end

  test ".format(98_765.4321)" do
    assert format(98_765.4321) == "98.77ms"
  end

  test ".format(987_654.321)" do
    assert format(987_654.321) == "987.65ms"
  end

  test ".format(9_876_543.21)" do
    assert format(9_876_543.21) == "9.88s"
  end

  test ".format(98_765_432.19)" do
    assert format(98_765_432.19) == "1.65m"
  end

  test ".format(987_654_321.9876)" do
    assert format(987_654_321.9876) == "16.46m"
  end

  test ".format(9_876_543_219.8765)" do
    assert format(9_876_543_219.8765) == "2.74h"
  end

  describe "Best unit for durations [1, 200, 3_000, 4_000_000, 55_000_000_000]" do
    setup do
      {:ok, list: [1, 200, 3_000, 4_000, 500_000, 6_000_000, 77_000_000_000]}
    end

    test ".best", %{list: list} do
      assert best(list) == :millisecond
    end

    test ".best, strategy: :smallest", %{list: list} do
      assert best(list, strategy: :smallest) == :microsecond
    end

    test ".best, strategy: :largest", %{list: list} do
      assert best(list, strategy: :largest) == :hour
    end
  end
end
