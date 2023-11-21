defmodule Benchee.RelativeStatistcsTest do
  use ExUnit.Case, async: true

  alias Benchee.{CollectionData, Scenario, Statistics, Suite}
  import Benchee.RelativeStatistics

  describe "computing relative statistics" do
    test "calculates relative statistics right" do
      suite = %Suite{
        scenarios: [
          scenario_with_average(394.0),
          scenario_with_average(14.0)
        ]
      }

      suite = relative_statistics(suite)
      time_stats = stats_from(suite)
      memory_stats = stats_from(suite, :memory_usage_data)

      Enum.each([time_stats, memory_stats], fn [stats1, stats2] ->
        assert stats1.absolute_difference == nil
        assert stats1.relative_more == nil
        assert stats1.relative_less == nil

        assert_in_delta stats2.relative_more, 28.14, 0.01
        assert_in_delta stats2.relative_less, 0.0355, 0.001
        assert stats2.absolute_difference == 380.0
      end)
    end

    test "doesn't calculate anything with just one scenario" do
      suite = %Suite{
        scenarios: [
          scenario_with_average(394.0)
        ]
      }

      suite = relative_statistics(suite)
      [stats] = stats_from(suite)

      assert stats.absolute_difference == nil
      assert stats.relative_more == nil
      assert stats.relative_less == nil
    end

    test "handles the fastest value being zerio alright" do
      suite = %Suite{
        scenarios: [
          scenario_with_average(0.0),
          scenario_with_average(100.0)
        ]
      }

      suite = relative_statistics(suite)
      [_stats1, stats2] = stats_from(suite, :memory_usage_data)

      assert stats2.relative_more == :infinity
      assert stats2.relative_less == 0.0
      assert stats2.absolute_difference == 100.0
    end

    test "handles the reference scenario not being the fastest" do
      # for instance what is fastest could consume the most memory,
      # but also upcoming reference feature
      suite = %Suite{
        scenarios: [
          scenario_with_average(50.0, 200.0),
          scenario_with_average(100.0, 100.0)
        ]
      }

      suite = relative_statistics(suite)
      [stats1, stats2] = stats_from(suite, :memory_usage_data)

      assert stats1.absolute_difference == nil
      assert stats1.relative_more == nil

      assert stats2.relative_more == 0.5
      assert stats2.relative_less == 2.0
      assert stats2.absolute_difference == -100.0
    end

    test "returns correct values when all measurements are zero" do
      suite = %Suite{
        scenarios: [
          scenario_with_average(0.0),
          scenario_with_average(0.0)
        ]
      }

      suite = relative_statistics(suite)
      [stats1, stats2] = stats_from(suite)

      assert stats1.absolute_difference == nil
      assert stats1.relative_more == nil

      assert stats2.relative_more == 1.0
      assert stats2.relative_less == 1.0
      assert stats2.absolute_difference == 0.0
    end
  end

  describe "sorting behaviour" do
    test "sorts them by their average run time fastest to slowest" do
      fourth = named_scenario_with_average("4", 400.1, nil)
      second = named_scenario_with_average("2", 200.0, nil)
      third = named_scenario_with_average("3", 400.0, nil)
      first = named_scenario_with_average("1", 100.0, nil)

      scenarios = [fourth, second, third, first]

      sorted = relative_statistics(%Suite{scenarios: scenarios}).scenarios

      assert Enum.map(sorted, fn scenario -> scenario.name end) == ["1", "2", "3", "4"]
    end

    test "sorts them by their average memory usage least to most" do
      fourth = named_scenario_with_average("4", nil, 400.1)
      second = named_scenario_with_average("2", nil, 200.0)
      third = named_scenario_with_average("3", nil, 400.0)
      first = named_scenario_with_average("1", nil, 100.0)

      scenarios = [fourth, second, third, first]

      sorted = relative_statistics(%Suite{scenarios: scenarios}).scenarios

      assert Enum.map(sorted, fn scenario -> scenario.name end) == ["1", "2", "3", "4"]
    end

    test "sorts them by their average run time using memory as a tie breaker" do
      second = named_scenario_with_average("2", 100.0, 100.0)
      third = named_scenario_with_average("3", 100.0, 100.1)
      first = named_scenario_with_average("1", 99.0, 200.0)

      scenarios = [second, third, first]

      sorted = relative_statistics(%Suite{scenarios: scenarios}).scenarios

      assert Enum.map(sorted, fn scenario -> scenario.name end) == ["1", "2", "3"]
    end
  end

  describe "dealing correctly with different inputs" do
    test "if it's just 2 scenarios with different inputs nothing is done" do
      suite = %Suite{
        scenarios: [
          named_input_scenario_with_average("A", "1", 100.0),
          named_input_scenario_with_average("A", "10", 100.0)
        ]
      }

      suite = relative_statistics(suite)
      stats = stats_from(suite)

      Enum.each(stats, fn stat ->
        refute stat.absolute_difference
        refute stat.relative_more
        refute stat.relative_less
      end)
    end

    test "calculate the correct relatives based on input names" do
      suite = %Suite{
        scenarios: [
          named_input_scenario_with_average("A", "1", 100.0),
          named_input_scenario_with_average("B", "1", 250.0),
          named_input_scenario_with_average("A", "10", 1000.0),
          named_input_scenario_with_average("B", "10", 3000.0)
        ]
      }

      suite = relative_statistics(suite)

      stats =
        suite.scenarios
        |> Enum.map(
          &{&1.name, &1.input_name, &1.run_time_data.statistics.absolute_difference,
           &1.run_time_data.statistics.relative_more}
        )
        |> Enum.sort()

      assert stats == [
               {"A", "1", nil, nil},
               {"A", "10", nil, nil},
               {"B", "1", 150.0, 2.5},
               {"B", "10", 2000.0, 3.0}
             ]
    end

    test "calculate the correct relatives based on different ordering" do
      suite = %Suite{
        scenarios: [
          named_input_scenario_with_average("A", "1", 100.0),
          named_input_scenario_with_average("A", "10", 1000.0),
          named_input_scenario_with_average("B", "1", 250.0),
          named_input_scenario_with_average("B", "10", 3000.0)
        ]
      }

      suite = relative_statistics(suite)

      stats =
        suite.scenarios
        |> Enum.map(
          &{&1.name, &1.input_name, &1.run_time_data.statistics.absolute_difference,
           &1.run_time_data.statistics.relative_more}
        )
        |> Enum.sort()

      assert stats == [
               {"A", "1", nil, nil},
               {"A", "10", nil, nil},
               {"B", "1", 150.0, 2.5},
               {"B", "10", 2000.0, 3.0}
             ]
    end

    test "maintains original input order" do
      suite = %Suite{
        scenarios: [
          named_input_scenario_with_average("A", "B", 100.0),
          named_input_scenario_with_average("A", "1000", 1000.0),
          named_input_scenario_with_average("A", "1", 250.0),
          named_input_scenario_with_average("A", "10", 3000.0),
          named_input_scenario_with_average("A", "A", 3000.0)
        ]
      }

      suite = relative_statistics(suite)

      assert Enum.map(suite.scenarios, & &1.input_name) == ["B", "1000", "1", "10", "A"]
    end
  end

  defp named_input_scenario_with_average(name, input_name, average) do
    scenario = scenario_with_average(average)

    %Scenario{scenario | name: name, input_name: input_name}
  end

  defp named_scenario_with_average(name, average, memory_average) do
    scenario = scenario_with_average(average, memory_average)

    put_in(scenario.name, name)
  end

  defp scenario_with_average(average, memory_average \\ false) do
    %Scenario{
      run_time_data: %CollectionData{
        statistics: %Statistics{average: average}
      },
      memory_usage_data: %CollectionData{
        statistics: %Statistics{
          average: if(memory_average == false, do: average, else: memory_average)
        }
      }
    }
  end

  defp stats_from(suite, type \\ :run_time_data) do
    Enum.map(suite.scenarios, fn scenario ->
      Map.fetch!(scenario, type).statistics
    end)
  end
end
