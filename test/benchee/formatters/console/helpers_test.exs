defmodule Benchee.Formatters.Console.HelpersTest do
  use ExUnit.Case, async: true

  alias Benchee.Formatters.Console.Helpers
  alias Benchee.Statistics

  test "missing percentile cannot silently use a different rank" do
    assert_raise KeyError, fn -> Helpers.percentile_value(%{90 => 100}, 99) end
    assert Helpers.percentile_value(%{90 => 0}, 90) == 0
  end

  test "empty calculated percentiles have no displayed rank" do
    assert Helpers.displayed_percentile([]) == nil
    assert Helpers.displayed_percentile([%Statistics{percentiles: %{}}]) == nil
    assert Helpers.displayed_percentile([%Statistics{percentiles: nil}]) == nil
  end
end
