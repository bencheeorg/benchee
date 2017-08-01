defmodule Benchee.Formatters.Console do
  @moduledoc """
  Formatter to transform the statistics output into a structure suitable for
  output through `IO.write` on the console.
  """

  alias Benchee.{Statistics, Suite, Benchmark.Scenario}
  alias Benchee.Conversion.{Count, Duration, Unit, DeviationPercent}

  @type unit_per_statistic :: %{atom => Unit.t}

  @default_label_width 4 # Length of column header
  @ips_width 13
  @average_width 15
  @deviation_width 11
  @median_width 15

  @doc """
  Formats the benchmark statistics using `Benchee.Formatters.Console.format/1`
  and then prints it out directly to the console using `IO.write/1`
  """
  @spec output(Suite.t) :: Suite.t
  def output(suite = %Suite{}) do
    suite
    |> format
    |> IO.write

    suite
  end

  @doc """
  Formats the benchmark statistics to a report suitable for output on the CLI.

  Returns a list of lists, where each list element is a group belonging to one
  specific input. So if there only was one (or no) input given through `:inputs`
  then there's just one list inside.

  ## Examples

  ```
  iex> scenarios = [
  ...>   %Benchee.Benchmark.Scenario{
  ...>     job_name: "My Job", input_name: "My input", run_time_statistics: %Benchee.Statistics{
  ...>       average: 200.0, ips: 5000.0,std_dev_ratio: 0.1, median: 190.0
  ...>     }
  ...>   },
  ...>   %Benchee.Benchmark.Scenario{
  ...>     job_name: "Job 2", input_name: "My input", run_time_statistics: %Benchee.Statistics{
  ...>       average: 400.0, ips: 2500.0, std_dev_ratio: 0.2, median: 390.0
  ...>     }
  ...>   }
  ...> ]
  iex> suite = %Benchee.Suite{
  ...>   scenarios: scenarios,
  ...>   configuration: %Benchee.Configuration{
  ...>     formatter_options: %{
  ...>       console: %{comparison: false, unit_scaling: :best}
  ...>     }
  ...>   }
  ...> }
  iex> Benchee.Formatters.Console.format(suite)
  [["\n##### With input My input #####", "\nName             ips        average  deviation         median\n",
  "My Job        5.00 K      200.00 μs    ±10.00%      190.00 μs\n",
  "Job 2         2.50 K      400.00 μs    ±20.00%      390.00 μs\n"]]

  ```

  """
  @spec format(Suite.t) :: [any]
  def format(%Suite{scenarios: scenarios,
                    configuration: %{formatter_options: %{console: config}}}) do
    scenarios
    |> Enum.group_by(fn(scenario) -> scenario.input_name end)
    |> Enum.map(fn({input, scenarios}) ->
        [input_header(input) | format_scenarios(scenarios, config)]
      end)
  end

  @no_input_marker Benchee.Benchmark.no_input()
  defp input_header(input) do
    case input do
      @no_input_marker -> ""
      _                -> "\n##### With input #{input} #####"
    end
  end

  @doc """
  Formats the job statistics to a report suitable for output on the CLI.

  ## Examples

  ```
  iex> scenarios = [
  ...>   %Benchee.Benchmark.Scenario{
  ...>     job_name: "My Job", run_time_statistics: %Benchee.Statistics{
  ...>       average: 200.0, ips: 5000.0,std_dev_ratio: 0.1, median: 190.0
  ...>     }
  ...>   },
  ...>   %Benchee.Benchmark.Scenario{
  ...>     job_name: "Job 2", run_time_statistics: %Benchee.Statistics{
  ...>       average: 400.0, ips: 2500.0, std_dev_ratio: 0.2, median: 390.0
  ...>     }
  ...>   }
  ...> ]
  iex> configuration = %{comparison: false, unit_scaling: :best}
  iex> Benchee.Formatters.Console.format_scenarios(scenarios, configuration)
  ["\nName             ips        average  deviation         median\n",
  "My Job        5.00 K      200.00 μs    ±10.00%      190.00 μs\n",
  "Job 2         2.50 K      400.00 μs    ±20.00%      390.00 μs\n"]

  ```

  """
  @spec format_scenarios([Scenario.t], map) :: [any, ...]
  def format_scenarios(scenarios, config) do
    sorted_scenarios = Statistics.sort(scenarios)
    units = units(sorted_scenarios, config)
    label_width = label_width(sorted_scenarios)

    [column_descriptors(label_width) |
      scenario_reports(sorted_scenarios, units, label_width)
      ++ comparison_report(sorted_scenarios, units, label_width, config)]
  end

  defp column_descriptors(label_width) do
    "\n~*s~*s~*s~*s~*s\n"
    |> :io_lib.format([-label_width, "Name", @ips_width, "ips",
                       @average_width, "average",
                       @deviation_width, "deviation", @median_width, "median"])
    |> to_string
  end

  defp label_width(scenarios) do
    max_label_width =
      scenarios
      |> Enum.map(fn(scenario) -> String.length(scenario.job_name) end)
      |> Stream.concat([@default_label_width])
      |> Enum.max
    max_label_width + 1
  end

  defp scenario_reports(scenarios, units, label_width) do
    Enum.map(scenarios,
             fn(scenario) -> format_scenario(scenario, units, label_width) end)
  end

  defp units(scenarios, %{unit_scaling: scaling_strategy}) do
    # Produces a map like
    #   %{run_time: [12345, 15431, 13222], ips: [1, 2, 3]}
    measurements =
      scenarios
      |> Enum.flat_map(fn(scenario) ->
           Map.to_list(scenario.run_time_statistics)
         end)
      |> Enum.group_by(fn({stat_name, _}) -> stat_name end,
                       fn({_, value}) -> value end)

    %{
      run_time: Duration.best(measurements.average, strategy: scaling_strategy),
      ips:      Count.best(measurements.ips, strategy: scaling_strategy),
    }
  end

  @spec format_scenario(Scenario.t, unit_per_statistic, integer) :: String.t
  defp format_scenario(%Scenario{
                         job_name: name,
                         run_time_statistics: %Statistics{
                           average:       average,
                           ips:           ips,
                           std_dev_ratio: std_dev_ratio,
                           median:        median
                         }
                       },
                       %{run_time: run_time_unit,
                         ips:      ips_unit,
                       }, label_width) do
    "~*s~*ts~*ts~*ts~*ts\n"
    |> :io_lib.format([-label_width, name, @ips_width, ips_out(ips, ips_unit),
                       @average_width, run_time_out(average, run_time_unit),
                       @deviation_width, deviation_out(std_dev_ratio),
                       @median_width, run_time_out(median, run_time_unit)])
    |> to_string
  end

  defp ips_out(ips, unit) do
    Count.format({Count.scale(ips, unit), unit})
  end

  defp run_time_out(average, unit) do
    Duration.format({Duration.scale(average, unit), unit})
  end

  defp deviation_out(std_dev_ratio) do
    DeviationPercent.format(std_dev_ratio)
  end

  @spec comparison_report([Scenario.t], unit_per_statistic, integer, map)
    :: [String.t]
  defp comparison_report(scenarios, units, label_width, config)
  defp comparison_report([_scenario], _, _, _) do
    [] # No need for a comparison when only one benchmark was run
  end
  defp comparison_report(_, _, _, %{comparison: false}) do
    []
  end
  defp comparison_report([scenario | other_scenarios], units, label_width, _) do
    [
      comparison_descriptor(),
      reference_report(scenario, units, label_width) |
      comparisons(scenario, units, label_width, other_scenarios)
    ]
  end

  defp reference_report(%Scenario{job_name: name,
                                  run_time_statistics: %Statistics{ips: ips}},
                        %{ips: ips_unit}, label_width) do
    "~*s~*s\n"
    |> :io_lib.format([-label_width, name, @ips_width, ips_out(ips, ips_unit)])
    |> to_string
  end

  @spec comparisons(Scenario.t, unit_per_statistic, integer, [Scenario.t])
    :: [String.t]
  defp comparisons(%Scenario{run_time_statistics: reference_stats},
                   units, label_width, scenarios_to_compare) do
    Enum.map(scenarios_to_compare,
      fn(scenario = %Scenario{run_time_statistics: job_stats}) ->
        slower = (reference_stats.ips / job_stats.ips)
        format_comparison(scenario, units, label_width, slower)
      end
    )
  end

  defp format_comparison(%Scenario{job_name: name,
                                   run_time_statistics: %Statistics{ips: ips}},
                         %{ips: ips_unit}, label_width, slower) do
    ips_format = ips_out(ips, ips_unit)
    "~*s~*s - ~.2fx slower\n"
    |> :io_lib.format([-label_width, name, @ips_width, ips_format, slower])
    |> to_string
  end

  defp comparison_descriptor do
    "\nComparison: \n"
  end
end
