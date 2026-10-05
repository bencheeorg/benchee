defmodule Benchee.Formatters.Console.HelpersTest do
  use ExUnit.Case, async: true

  alias Benchee.CollectionData
  alias Benchee.Formatters.Console.Helpers
  alias Benchee.Scenario
  alias Benchee.Statistics

  describe "percentile_output/3" do
    test "formats the value of the given rank" do
      assert Helpers.percentile_output(%{90 => 0}, 90, &to_string/1) == "0"
    end

    test "a missing rank cannot silently use a different one" do
      assert Helpers.percentile_output(%{90 => 100}, 99, &to_string/1) == "N/A"
    end

    test "is N/A without a rank or percentiles" do
      assert Helpers.percentile_output(%{90 => 100}, nil, &to_string/1) == "N/A"
      assert Helpers.percentile_output(nil, 90, &to_string/1) == "N/A"
    end
  end

  describe "displayed_percentile/2" do
    test "is the highest calculated rank across scenarios" do
      scenarios = [
        scenario(%Statistics{percentiles: %{50 => 1, 90 => 2}}),
        scenario(%Statistics{percentiles: %{99 => 3}})
      ]

      assert Helpers.displayed_percentile(scenarios, :run_time_data) == 99
    end

    test "works for the other kinds of data" do
      scenarios = [
        %Scenario{
          name: "memory",
          memory_usage_data: %CollectionData{statistics: %Statistics{percentiles: %{75 => 1}}}
        }
      ]

      assert Helpers.displayed_percentile(scenarios, :memory_usage_data) == 75
    end

    test "empty calculated percentiles have no displayed rank" do
      assert Helpers.displayed_percentile([], :run_time_data) == nil

      assert Helpers.displayed_percentile(
               [scenario(%Statistics{percentiles: %{}})],
               :run_time_data
             ) == nil

      assert Helpers.displayed_percentile(
               [scenario(%Statistics{percentiles: nil})],
               :run_time_data
             ) == nil
    end
  end

  defp scenario(statistics) do
    %Scenario{name: "job", run_time_data: %CollectionData{statistics: statistics}}
  end
end
