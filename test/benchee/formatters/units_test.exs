defmodule Benchee.Formatters.UnitsTest do
  use ExUnit.Case
  import Benchee.Units

  test ".format 123_456_789_012 scales to :billion" do
    assert scale_count(123_456_789_012) == {123.456789012, :billion}
  end

  test ".format 12_345_678_901 scales to :billion" do
    assert scale_count(12_345_678_901) == {12.345678901, :billion}
  end

  test ".format 1_234_567_890 scales to :billion" do
    assert scale_count(1_234_567_890) == {1.23456789, :billion}
  end

  test ".format 123_456_789 scales to :million" do
    assert scale_count(123_456_789) == {123.456789, :million}
  end

  test ".format 12_345_678 scales to :million" do
    assert scale_count(12_345_678) == {12.345678, :million}
  end

  test ".format 1_234_567 scales to :million" do
    assert scale_count(1_234_567) == {1.234567, :million}
  end

  test ".format 123_456.7 scales to :thousand" do
    assert scale_count(123_456.7) == {123.4567, :thousand}
  end

  test ".format 12_345.67 scales to :thousand" do
    assert scale_count(12_345.67) == {12.34567, :thousand}
  end

  test ".format 1_234.567 scales to :thousand" do
    assert scale_count(1_234.567) == {1.234567, :thousand}
  end

  test ".format 123.4567 scales to :one" do
    assert scale_count(123.4567) == {123.4567, :one}
  end

  test ".format 12.34567 scales to :one" do
    assert scale_count(12.34567) == {12.34567, :one}
  end

  test ".format 1.234567 scales to :one" do
    assert scale_count(1.234567) == {1.234567, :one}
  end

  test ".format 0.001234567 scales to :one" do
    assert scale_count(0.001234567) == {0.001234567, :one}
  end

  test ".format_count(1_234_567)" do
    assert format_count(1_000_000) == "1.00M"
  end
end
