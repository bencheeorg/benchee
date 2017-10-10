defmodule Benchee.Statistics.PercentileTest do
  use ExUnit.Case, async: true
  alias Benchee.Statistics.Percentile
  doctest Percentile

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

  @tag run: true
  test "90th percentile" do
    result = Percentile.percentile(@nist_sample_data, 90)
    assert Float.round(result, 4) == 95.1981
  end
end
