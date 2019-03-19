defmodule Benchee.Formatters.Console.RunTime do
  @moduledoc false

  # This deals with just the formatting of the run time results. They are similar
  # to the way the memory results are formatted, but different enough to where the
  # abstractions start to break down pretty significantly, so I wanted to extract
  # these two things into separate modules to avoid confusion.

  alias Benchee.{
    Conversion,
    Conversion.Count,
    Conversion.Duration,
    Conversion.Unit,
    Formatters.Console.Helpers,
    Scenario,
    Statistics
  }

  @type unit_per_statistic :: %{atom => Unit.t()}

  @ips_width 13
  @average_width 15
  @deviation_width 11
  @median_width 15
  @percentile_width 15
  @minimum_width 15
  @maximum_width 15
  @sample_size_width 15
  @mode_width 25

  @doc """
  Formats the run time statistics to a report suitable for output on the CLI.

  ## Examples

  ```
  iex> memory_statistics = %Benchee.Statistics{average: 100.0}
  iex> scenarios = [
  ...>   %Benchee.Scenario{
  ...>     name: "My Job",
  ...>     run_time_data: %Benchee.CollectionData{
  ...>       statistics: %Benchee.Statistics{
  ...>         average: 200.0, ips: 5000.0,std_dev_ratio: 0.1, median: 190.0, percentiles: %{99 => 300.1},
  ...>         minimum: 100.1, maximum: 200.2, sample_size: 10_101, mode: 333.2
  ...>       },
  ...>     },
  ...>     memory_usage_data: %Benchee.CollectionData{statistics: memory_statistics}
  ...>   },
  ...>   %Benchee.Scenario{
  ...>     name: "Job 2",
  ...>     run_time_data: %Benchee.CollectionData{
  ...>       statistics: %Benchee.Statistics{
  ...>         average: 400.0, ips: 2500.0, std_dev_ratio: 0.2, median: 390.0, percentiles: %{99 => 500.1},
  ...>         minimum: 200.2, maximum: 400.4, sample_size: 20_202, mode: [612.3, 554.1]
  ...>       }
  ...>     },
  ...>     memory_usage_data: %Benchee.CollectionData{statistics: memory_statistics}
  ...>   }
  ...> ]
  iex> configuration = %{comparison: false, unit_scaling: :best, extended_statistics: true}
  iex> Benchee.Formatters.Console.RunTime.format_scenarios(scenarios, configuration)
  ["\nName             ips        average  deviation         median         99th %\n",
  "My Job           5 K         200 ns    ±10.00%         190 ns      300.10 ns\n",
  "Job 2         2.50 K         400 ns    ±20.00%         390 ns      500.10 ns\n",
  "\nExtended statistics: \n",
  "\nName           minimum        maximum    sample size                     mode\n",
  "My Job       100.10 ns      200.20 ns        10.10 K                333.20 ns\n",
  "Job 2        200.20 ns      400.40 ns        20.20 K     612.30 ns, 554.10 ns\n"]

  ```

  """
  @spec format_scenarios([Scenario.t()], map) :: [String.t(), ...]
  def format_scenarios(scenarios, config) do
    if run_time_measurements_present?(scenarios) do
      render(scenarios, config)
    else
      []
    end
  end

  defp run_time_measurements_present?(scenarios) do
    Enum.any?(scenarios, fn scenario ->
      scenario.run_time_data.statistics.sample_size > 0
    end)
  end

  defp render(scenarios, config) do
    %{unit_scaling: scaling_strategy} = config
    units = Conversion.units(scenarios, scaling_strategy)
    label_width = Helpers.label_width(scenarios)

    List.flatten([
      column_descriptors(label_width),
      scenario_reports(scenarios, units, label_width),
      comparison_report(scenarios, units, label_width, config),
      extended_statistics_report(scenarios, units, label_width, config)
    ])
  end

  @spec extended_statistics_report([Scenario.t()], unit_per_statistic, integer, map) :: [
          String.t()
        ]
  defp extended_statistics_report(scenarios, units, label_width, %{extended_statistics: true}) do
    [
      Helpers.descriptor("Extended statistics"),
      extended_column_descriptors(label_width)
      | extended_statistics(scenarios, units, label_width)
    ]
  end

  defp extended_statistics_report(_, _, _, _) do
    []
  end

  @spec extended_statistics([Scenario.t()], unit_per_statistic, integer) :: [String.t()]
  defp extended_statistics(scenarios, units, label_width) do
    Enum.map(scenarios, fn scenario ->
      format_scenario_extended(scenario, units, label_width)
    end)
  end

  @spec format_scenario_extended(Scenario.t(), unit_per_statistic, integer) :: String.t()
  defp format_scenario_extended(scenario, %{run_time: run_time_unit}, label_width) do
    %Scenario{
      name: name,
      run_time_data: %{
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
      duration_output(minimum, run_time_unit),
      @maximum_width,
      duration_output(maximum, run_time_unit),
      @sample_size_width,
      Count.format(sample_size),
      @mode_width,
      Helpers.mode_out(mode, run_time_unit)
    ])
    |> to_string
  end

  @spec extended_column_descriptors(integer) :: String.t()
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

  @spec column_descriptors(integer) :: String.t()
  defp column_descriptors(label_width) do
    "\n~*s~*s~*s~*s~*s~*s\n"
    |> :io_lib.format([
      -label_width,
      "Name",
      @ips_width,
      "ips",
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

  @spec scenario_reports([Scenario.t()], unit_per_statistic, integer) :: [String.t()]
  defp scenario_reports(scenarios, units, label_width) do
    Enum.map(scenarios, fn scenario ->
      format_scenario(scenario, units, label_width)
    end)
  end

  @spec format_scenario(Scenario.t(), unit_per_statistic, integer) :: String.t()
  defp format_scenario(scenario, %{run_time: run_time_unit, ips: ips_unit}, label_width) do
    %Scenario{
      name: name,
      run_time_data: %{
        statistics: %Statistics{
          average: average,
          ips: ips,
          std_dev_ratio: std_dev_ratio,
          median: median,
          percentiles: %{99 => percentile_99}
        }
      }
    } = scenario

    "~*s~*ts~*ts~*ts~*ts~*ts\n"
    |> :io_lib.format([
      -label_width,
      name,
      @ips_width,
      Helpers.count_output(ips, ips_unit),
      @average_width,
      duration_output(average, run_time_unit),
      @deviation_width,
      Helpers.deviation_output(std_dev_ratio),
      @median_width,
      duration_output(median, run_time_unit),
      @percentile_width,
      duration_output(percentile_99, run_time_unit)
    ])
    |> to_string
  end

  @spec comparison_report([Scenario.t()], unit_per_statistic, integer, map) :: [String.t()]
  defp comparison_report(scenarios, units, label_width, config)

  # No need for a comparison when only one benchmark was run
  defp comparison_report([_scenario], _, _, _), do: []
  defp comparison_report(_, _, _, %{comparison: false}), do: []

  defp comparison_report([scenario | other_scenarios], units, label_width, _) do
    [
      Helpers.descriptor("Comparison"),
      reference_report(scenario, units, label_width)
      | comparisons(other_scenarios, units, label_width)
    ]
  end

  defp reference_report(scenario, %{ips: ips_unit}, label_width) do
    %Scenario{name: name, run_time_data: %{statistics: %Statistics{ips: ips}}} = scenario

    "~*s~*s\n"
    |> :io_lib.format([-label_width, name, @ips_width, Helpers.count_output(ips, ips_unit)])
    |> to_string
  end

  @spec comparisons([Scenario.t()], unit_per_statistic, integer) :: [String.t()]
  defp comparisons(scenarios_to_compare, units, label_width) do
    Enum.map(
      scenarios_to_compare,
      fn scenario ->
        statistics = scenario.run_time_data.statistics
        ips_format = Helpers.count_output(statistics.ips, units.ips)

        Helpers.format_comparison(
          scenario.name,
          statistics,
          ips_format,
          "slower",
          units.run_time,
          label_width,
          @ips_width
        )
      end
    )
  end

  defp duration_output(duration, unit) do
    Duration.format({Duration.scale(duration, unit), unit})
  end
end
