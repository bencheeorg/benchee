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
    setup do
      {:ok, samples: [300]}
    end

    test "1st percentile", %{samples: samples} do
      %{1 => result} = percentiles(samples, [1])
      assert result == 300.0
    end

    test "50th percentile", %{samples: samples} do
      %{50 => result} = percentiles(samples, [50])
      assert result == 300.0
    end

    test "99th percentile", %{samples: samples} do
      %{99 => result} = percentiles(samples, [99])
      assert result == 300.0
    end
  end

  describe "a list of two elements" do
    setup do
      {:ok, samples: [300, 200]}
    end

    test "1st percentile", %{samples: samples} do
      %{1 => result} = percentiles(samples, [1])
      assert result == 203.0
    end

    test "50th percentile", %{samples: samples} do
      %{50 => result} = percentiles(samples, [50])
      assert result == 250.0
    end

    test "99th percentile", %{samples: samples} do
      %{99 => result} = percentiles(samples, [99])
      assert result == 300.0
    end
  end

  describe "a list of three elements" do
    setup do
      {:ok, samples: [100, 300, 200]}
    end

    test "1st percentile", %{samples: samples} do
      %{1 => result} = percentiles(samples, [1])
      assert result == 104.0
    end

    test "50th percentile", %{samples: samples} do
      %{50 => result} = percentiles(samples, [50])
      assert result == 200.0
    end

    test "99th percentile", %{samples: samples} do
      %{99 => result} = percentiles(samples, [99])
      assert result == 300.0
    end
  end
end
