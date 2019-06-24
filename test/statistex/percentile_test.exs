defmodule Statistex.PercentileTest do
  use ExUnit.Case, async: true
  import Statistex.Percentile

  doctest Statistex.Percentile

  @nist_sample_data [
    95.1772,
    95.1567,
    95.1937,
    95.1959,
    95.1442,
    95.0610,
    95.1591,
    95.1195,
    95.1065,
    95.0925,
    95.1990,
    95.1682
  ]

  # Test data from:
  #   http://www.itl.nist.gov/div898/handbook/prc/section2/prc262.htm
  test "90th percentile" do
    %{90 => result} = percentiles(@nist_sample_data, 90)
    assert Float.round(result, 4) == 95.1981
  end

  test "an empty list raises an argument error" do
    assert_raise ArgumentError, fn -> percentiles([], [1]) end
  end

  describe "a list of one element" do
    @samples [300]
    test "1st percentile" do
      %{1 => result} = percentiles(@samples, [1])
      assert result == 300.0
    end

    test "50th percentile" do
      %{50 => result} = percentiles(@samples, [50])
      assert result == 300.0
    end

    test "99th percentile" do
      %{99 => result} = percentiles(@samples, [99])
      assert result == 300.0
    end
  end

  describe "a list of two elements" do
    @samples [300, 200]
    test "1st percentile (small sample size simply picks first element)" do
      %{1 => result} = percentiles(@samples, [1])
      assert result == 200.0
    end

    test "50th percentile" do
      %{50 => result} = percentiles(@samples, [50])
      assert result == 250.0
    end

    test "99th percentile" do
      %{99 => result} = percentiles(@samples, [99])
      assert result == 300.0
    end
  end

  describe "seemingly problematic 2 element list [9, 1]" do
    @samples [9, 1]

    percentiles = %{
      25 => 1,
      50 => 5,
      75 => 9.0,
      90 => 9.0,
      99 => 9.0
    }

    for {percentile, expected} <- percentiles do
      @percentile percentile
      @expected expected
      test "#{percentile}th percentile" do
        %{@percentile => result} = percentiles(@samples, [@percentile])
        assert result == @expected
      end
    end
  end

  describe "a list of three elements" do
    @samples [100, 300, 200]
    test "1st percentile (small sample size simply picks first element)" do
      %{1 => result} = percentiles(@samples, [1])
      assert result == 100.0
    end

    test "50th percentile" do
      %{50 => result} = percentiles(@samples, [50])
      assert result == 200.0
    end

    test "99th percentile" do
      %{99 => result} = percentiles(@samples, [99])
      assert result == 300.0
    end
  end
end
