defmodule Benchee.Formatters.Console.Memory do
  @moduledoc false

  # This deals with just the formatting of the run time results. They are similar
  # to the way the memory results are formatted, but different enough to where the
  # abstractions start to break down pretty significantly, so I wanted to extract
  # these two things into separate modules to avoid confusion.

  alias Benchee.{
    Conversion,
    Conversion.Count,
    Conversion.Memory,
    Conversion.Unit,
    Formatters.Console.Helpers,
    Scenario,
    Statistics
  }

  @type unit_per_statistic :: %{atom => Unit.t()}

  # Length of column header
  @average_width 15
  @deviation_width 11
  @median_width 15
  @percentile_width 15
  @minimum_width 15
  @maximum_width 15
  @sample_size_width 15
  @mode_width 25

  @doc """
  Formats the memory statistics to a report suitable for output on the CLI. If
  all memory measurements are the same and we have a standard deviation of 0.0
  for each scenario, we don't show the statistics and report just on the single
  measured memory usage.
  """
  @spec format_scenarios([Scenario.t()], map) :: [String.t(), ...]
  def format_scenarios(scenarios, config) do
    if memory_measurements_present?(scenarios) do
      render(scenarios, config)
    else
      []
    end
  end

  defp memory_measurements_present?(scenarios) do
    Enum.any?(scenarios, fn scenario ->
      scenario.memory_usage_data.statistics.sample_size > 0
    end)
  end

  defp render(scenarios, config) do
    scaling_strategy = config.unit_scaling
    units = Conversion.units(scenarios, scaling_strategy)
    label_width = Helpers.label_width(scenarios)
    hide_statistics = all_have_deviation_of_0?(scenarios)

    List.flatten([
      "\nMemory usage statistics:\n",
      column_descriptors(label_width, hide_statistics),
      scenario_reports(scenarios, units, label_width, hide_statistics),
      comparison_report(scenarios, units, label_width, config, hide_statistics),
      extended_statistics_report(scenarios, units, label_width, config, hide_statistics)
    ])
  end

  defp all_have_deviation_of_0?(scenarios) do
    Enum.all?(scenarios, fn scenario ->
      scenario.memory_usage_data.statistics.std_dev == 0.0
    end)
  end

  defp column_descriptors(label_width, hide_statistics)

  defp column_descriptors(label_width, false) do
    "\n~*s~*s~*s~*s~*s\n"
    |> :io_lib.format([
      -label_width,
      "Name",
      @average_width,
      "average",
      @deviation_width,
      "deviation",
      @median_width,
      "median",
      @percentile_width,
      "99th %"
    ])
    |> to_string
  end

  defp column_descriptors(label_width, true) do
    "\n~*s~*s\n"
    |> :io_lib.format([
      -label_width,
      "Name",
      @average_width,
      "Memory usage"
    ])
    |> to_string
  end

  @spec scenario_reports([Scenario.t()], unit_per_statistic, integer, boolean) :: [String.t()]
  defp scenario_reports(scenarios, units, label_width, hide_statistics)

  defp scenario_reports([scenario | other_scenarios], units, label_width, true) do
    [
      reference_report(scenario, units, label_width),
      comparisons(other_scenarios, units, label_width),
      "\n**All measurements for memory usage were the same**\n"
    ]
  end

  defp scenario_reports(scenarios, units, label_width, hide_statistics) do
    Enum.map(scenarios, fn scenario ->
      format_scenario(scenario, units, label_width, hide_statistics)
    end)
  end

  @na "N/A"

  @spec format_scenario(Scenario.t(), unit_per_statistic, integer, boolean) :: String.t()
  defp format_scenario(scenario, units, label_width, hide_statistics)

  defp format_scenario(
         scenario = %Scenario{memory_usage_data: %{statistics: %{sample_size: 0}}},
         _,
         label_width,
         _
       ) do
    warning =
      "WARNING the scenario \"#{scenario.name}\" has no memory measurements!" <>
        " This is probably a bug please report it!\n" <>
        "https://github.com/PragTob/benchee/issues/new"

    data =
      "~*ts~*ts\n"
      |> :io_lib.format([
        -label_width,
        scenario.name,
        @average_width,
        @na
      ])
      |> to_string

    warning <> "\n" <> data
  end

  defp format_scenario(scenario, %{memory: memory_unit}, label_width, false) do
    %Scenario{
      name: name,
      memory_usage_data: %{
        statistics: %Statistics{
          average: average,
          std_dev_ratio: std_dev_ratio,
          median: median,
          percentiles: %{99 => percentile_99}
        }
      }
    } = scenario

    "~*ts~*ts~*ts~*ts~*ts\n"
    |> :io_lib.format([
      -label_width,
      name,
      @average_width,
      memory_output(average, memory_unit),
      @deviation_width,
      Helpers.deviation_output(std_dev_ratio),
      @median_width,
      memory_output(median, memory_unit),
      @percentile_width,
      memory_output(percentile_99, memory_unit)
    ])
    |> to_string
  end

  defp format_scenario(scenario, %{memory: memory_unit}, label_width, true) do
    %Scenario{
      name: name,
      memory_usage_data: %{
        statistics: %Statistics{
          average: average
        }
      }
    } = scenario

    "~*ts~*ts\n"
    |> :io_lib.format([
      -label_width,
      name,
      @average_width,
      memory_output(average, memory_unit)
    ])
    |> to_string
  end

  @spec comparison_report([Scenario.t()], unit_per_statistic, integer, map, boolean) :: [
          String.t()
        ]
  defp comparison_report(scenarios, units, label_width, config, hide_statistics)

  # No need for a comparison when only one benchmark was run
  defp comparison_report([_scenario], _, _, _, _), do: []
  defp comparison_report(_, _, _, %{comparison: false}, _), do: []
  defp comparison_report(_, _, _, _, true), do: []

  defp comparison_report([scenario | other_scenarios], units, label_width, _, _) do
    [
      Helpers.descriptor("Comparison"),
      reference_report(scenario, units, label_width)
      | comparisons(other_scenarios, units, label_width)
    ]
  end

  defp reference_report(scenario, %{memory: memory_unit}, label_width) do
    %Scenario{name: name, memory_usage_data: %{statistics: %Statistics{median: median}}} =
      scenario

    "~*s~*s\n"
    |> :io_lib.format([
      -label_width,
      name,
      @median_width,
      memory_output(median, memory_unit)
    ])
    |> to_string
  end

  @spec comparisons([Scenario.t()], unit_per_statistic, integer) :: [String.t()]
  defp comparisons(scenarios_to_compare, units, label_width) do
    Enum.map(
      scenarios_to_compare,
      fn scenario ->
        statistics = scenario.memory_usage_data.statistics
        memory_format = memory_output(statistics.average, units.memory)

        Helpers.format_comparison(
          scenario.name,
          statistics,
          memory_format,
          "memory usage",
          units.memory,
          label_width,
          @median_width
        )
      end
    )
  end

  defp memory_output(nil, _unit), do: "N/A"

  defp memory_output(memory, unit) do
    Memory.format({Memory.scale(memory, unit), unit})
  end

  defp extended_statistics_report(scenarios, units, label_width, config, hide_statistics)
  defp extended_statistics_report(_, _, _, _, true), do: []

  defp extended_statistics_report(scenarios, units, label_width, %{extended_statistics: true}, _) do
    [
      Helpers.descriptor("Extended statistics"),
      extended_column_descriptors(label_width)
      | extended_statistics(scenarios, units, label_width)
    ]
  end

  defp extended_statistics_report(_, _, _, _, _), do: []

  defp extended_column_descriptors(label_width) do
    "\n~*s~*s~*s~*s~*s\n"
    |> :io_lib.format([
      -label_width,
      "Name",
      @minimum_width,
      "minimum",
      @maximum_width,
      "maximum",
      @sample_size_width,
      "sample size",
      @mode_width,
      "mode"
    ])
    |> to_string
  end

  defp extended_statistics(scenarios, units, label_width) do
    Enum.map(scenarios, fn scenario ->
      format_scenario_extended(scenario, units, label_width)
    end)
  end

  defp format_scenario_extended(scenario, %{memory: memory_unit}, label_width) do
    %Scenario{
      name: name,
      memory_usage_data: %{
        statistics: %Statistics{
          minimum: minimum,
          maximum: maximum,
          sample_size: sample_size,
          mode: mode
        }
      }
    } = scenario

    "~*s~*ts~*ts~*ts~*ts\n"
    |> :io_lib.format([
      -label_width,
      name,
      @minimum_width,
      Helpers.count_output(minimum, memory_unit),
      @maximum_width,
      Helpers.count_output(maximum, memory_unit),
      @sample_size_width,
      Count.format(sample_size),
      @mode_width,
      Helpers.mode_out(mode, memory_unit)
    ])
    |> to_string
  end
end
