defmodule Benchee.Unit.CountTest do
  use ExUnit.Case
  import Benchee.Unit.Count

  test ".format 123_456_789_012 scales to :billion" do
    assert scale(123_456_789_012) == {123.456789012, :billion}
  end

  test ".format 12_345_678_901 scales to :billion" do
    assert scale(12_345_678_901) == {12.345678901, :billion}
  end

  test ".format 1_234_567_890 scales to :billion" do
    assert scale(1_234_567_890) == {1.23456789, :billion}
  end

  test ".format 123_456_789 scales to :million" do
    assert scale(123_456_789) == {123.456789, :million}
  end

  test ".format 12_345_678 scales to :million" do
    assert scale(12_345_678) == {12.345678, :million}
  end

  test ".format 1_234_567 scales to :million" do
    assert scale(1_234_567) == {1.234567, :million}
  end

  test ".format 123_456.7 scales to :thousand" do
    assert scale(123_456.7) == {123.4567, :thousand}
  end

  test ".format 12_345.67 scales to :thousand" do
    assert scale(12_345.67) == {12.34567, :thousand}
  end

  test ".format 1_234.567 scales to :thousand" do
    assert scale(1_234.567) == {1.234567, :thousand}
  end

  test ".format 123.4567 scales to :one" do
    assert scale(123.4567) == {123.4567, :one}
  end

  test ".format 12.34567 scales to :one" do
    assert scale(12.34567) == {12.34567, :one}
  end

  test ".format 1.234567 scales to :one" do
    assert scale(1.234567) == {1.234567, :one}
  end

  test ".format 0.001234567 scales to :one" do
    assert scale(0.001234567) == {0.001234567, :one}
  end

  test ".format(1_000_000)" do
    assert format(1_000_000) == "1.00M"
  end

  test ".format(1_000.1234)" do
    assert format(1_000.1234) == "1.00K"
  end

  test ".format(123.4)" do
    assert format(123.4) == "123.40"
  end

  test ".format(1.234)" do
    assert format(1.234) == "1.23"
  end

  describe "Best unit for counts [1, 100, 1_000]" do
    setup do
      {:ok, list: [1, 100, 1_000]}
    end

    test ".best", %{list: list} do
      assert best(list) == :one
    end

    test ".best, strategy: :smallest", %{list: list} do
      assert best(list, strategy: :smallest) == :one
    end

    test ".best, strategy: :largest", %{list: list} do
      assert best(list, strategy: :largest) == :thousand
    end
  end

  describe "Best unit for counts [1, 1_000, 100_000, 1_000_000, 10_000_000, 1_000_000_000]" do
    setup do
      {:ok, list: [0.0001, 1, 1_000, 100_000, 1_000_000, 10_000_000, 1_000_000_000]}
    end

    test ".best", %{list: list} do
      assert best(list) == :million
    end

    test ".best, strategy: :smallest", %{list: list} do
      assert best(list, strategy: :smallest) == :one
    end

    test ".best, strategy: :largest", %{list: list} do
      assert best(list, strategy: :largest) == :billion
    end
  end

  describe "Best unit for counts [1_000, 2_000, 30_000]" do
    setup do
      {:ok, list: [1_000, 2_000, 30_000, 999]}
    end

    test ".best", %{list: list} do
      assert best(list) == :thousand
    end

    test ".best, strategy: :smallest", %{list: list} do
      assert best(list, strategy: :smallest) == :one
    end

    test ".best, strategy: :largest", %{list: list} do
      assert best(list, strategy: :largest) == :thousand
    end
  end
end
