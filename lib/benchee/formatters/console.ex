defmodule Benchee.Formatters.Console do
  @moduledoc """
  Formatter to transform the statistics output into a structure suitable for
  output through `IO.write` on the console.
  """

  use Benchee.Formatter

  alias Benchee.{
    Statistics, Suite, Benchmark.Scenario, Configuration, Conversion
  }
  alias Benchee.Conversion.{Count, Duration, Unit, DeviationPercent}

  @type unit_per_statistic :: %{atom => Unit.t}

  @default_label_width 4 # Length of column header
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
  Formats the benchmark statistics to a report suitable for output on the CLI.

  Returns a list of lists, where each list element is a group belonging to one
  specific input. So if there only was one (or no) input given through `:inputs`
  then there's just one list inside.

  ## Examples

  ```
  iex> scenarios = [
  ...>   %Benchee.Benchmark.Scenario{
  ...>     job_name: "My Job", input_name: "My input", run_time_statistics: %Benchee.Statistics{
  ...>       average: 200.0,ips: 5000.0,std_dev_ratio: 0.1, median: 190.0, percentiles: %{99 => 300.1}
  ...>     }
  ...>   },
  ...>   %Benchee.Benchmark.Scenario{
  ...>     job_name: "Job 2", input_name: "My input", run_time_statistics: %Benchee.Statistics{
  ...>       average: 400.0, ips: 2500.0, std_dev_ratio: 0.2, median: 390.0, percentiles: %{99 => 500.1}
  ...>     }
  ...>   }
  ...> ]
  iex> suite = %Benchee.Suite{
  ...>   scenarios: scenarios,
  ...>   configuration: %Benchee.Configuration{
  ...>     formatter_options: %{
  ...>       console: %{comparison: false, extended_statistics: false}
  ...>     },
  ...>     unit_scaling: :best
  ...>   }
  ...> }
  iex> Benchee.Formatters.Console.format(suite)
  [["\n##### With input My input #####", "\nName             ips        average  deviation         median         99th %\n",
  "My Job           5 K         200 μs    ±10.00%         190 μs      300.10 μs\n",
  "Job 2         2.50 K         400 μs    ±20.00%         390 μs      500.10 μs\n"]]

  ```

  """
  @spec format(Suite.t) :: [any]
  def format(%Suite{scenarios: scenarios, configuration: config}) do
    config = console_configuration(config)
    scenarios
    |> Enum.group_by(fn(scenario) -> scenario.input_name end)
    |> Enum.map(fn({input, scenarios}) ->
        [input_header(input) | format_scenarios(scenarios, config)]
      end)
  end

  @doc """
  Takes the output of `format/1` and writes that to the console.
  """
  @spec write(any) :: :ok | {:error, String.t}
  def write(output) do
    IO.write(output)
  rescue
    _ -> {:error, "Unknown Error"}
  end

  defp console_configuration(%Configuration{
                               formatter_options: %{console: config},
                               unit_scaling: scaling_strategy}) do
    if Map.has_key?(config, :unit_scaling), do: warn_unit_scaling()
    Map.put config, :unit_scaling, scaling_strategy
  end

  defp warn_unit_scaling do
    IO.puts "unit_scaling is now a top level configuration option, avoid passing it as a formatter option."
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
  ...>       average: 200.0, ips: 5000.0,std_dev_ratio: 0.1, median: 190.0, percentiles: %{99 => 300.1},
  ...>       minimum: 100.1, maximum: 200.2, sample_size: 10_101, mode: 333.2
  ...>     }
  ...>   },
  ...>   %Benchee.Benchmark.Scenario{
  ...>     job_name: "Job 2", run_time_statistics: %Benchee.Statistics{
  ...>       average: 400.0, ips: 2500.0, std_dev_ratio: 0.2, median: 390.0, percentiles: %{99 => 500.1},
  ...>       minimum: 200.2, maximum: 400.4, sample_size: 20_202, mode: [612.3, 554.1]
  ...>     }
  ...>   }
  ...> ]
  iex> configuration = %{comparison: false, unit_scaling: :best, extended_statistics: true}
  iex> Benchee.Formatters.Console.format_scenarios(scenarios, configuration)
  ["\nName             ips        average  deviation         median         99th %\n",
  "My Job           5 K         200 μs    ±10.00%         190 μs      300.10 μs\n",
  "Job 2         2.50 K         400 μs    ±20.00%         390 μs      500.10 μs\n",
  "\nExtended statistics: \n",
  "\nName           minimum        maximum    sample size                     mode\n",
  "My Job       100.10 μs      200.20 μs        10.10 K                333.20 μs\n",
  "Job 2        200.20 μs      400.40 μs        20.20 K     612.30 μs, 554.10 μs\n"]

  ```

  """
  @spec format_scenarios([Scenario.t], map) :: [String.t, ...]
  def format_scenarios(scenarios, config) do
    sorted_scenarios = Statistics.sort(scenarios)
    %{unit_scaling: scaling_strategy} = config
    units = Conversion.units(sorted_scenarios, scaling_strategy)
    label_width = label_width(sorted_scenarios)

    [column_descriptors(label_width) |
      scenario_reports(sorted_scenarios, units, label_width)
      ++ comparison_report(sorted_scenarios, units, label_width, config)
      ++ extended_statistics_report(
          sorted_scenarios, units, label_width, config)]
  end

  @spec extended_statistics_report(
    [Scenario.t], unit_per_statistic, integer, map) :: [String.t]
  defp extended_statistics_report(_, _, _, %{extended_statistics: false}) do
    []
  end
  defp extended_statistics_report(scenarios, units, label_width, _config) do
    [
      descriptor("Extended statistics"),
      extended_column_descriptors(label_width) |
      extended_statistics(scenarios, units, label_width)
    ]
  end

  @spec extended_statistics([Scenario.t], unit_per_statistic, integer)
    :: [String.t]
  defp extended_statistics(scenarios, units, label_width) do
    Enum.map(scenarios, fn(scenario) ->
      format_scenario_extended(scenario, units, label_width)
    end)
  end

  @spec format_scenario_extended(Scenario.t, unit_per_statistic, integer)
    :: String.t
  defp format_scenario_extended(%Scenario{
                                  job_name: name,
                                  run_time_statistics: %Statistics{
                                    minimum:     minimum,
                                    maximum:     maximum,
                                    sample_size: sample_size,
                                    mode:        mode
                                  }
                                },
                                %{run_time: run_time_unit},
                                label_width) do
    "~*s~*ts~*ts~*ts~*ts\n"
    |> :io_lib.format([
      -label_width, name,
      @minimum_width, run_time_out(minimum, run_time_unit),
      @maximum_width, run_time_out(maximum, run_time_unit),
      @sample_size_width, Count.format(sample_size),
      @mode_width, mode_out(mode, run_time_unit)])
    |> to_string
  end

  @spec mode_out(Statistics.mode, Benchee.Conversion.Unit.t) :: String.t
  defp mode_out(modes, _run_time_unit) when is_nil(modes) do
    "None"
  end
  defp mode_out(modes, run_time_unit) when is_list(modes) do
    Enum.map_join(modes, ", ", fn(mode) -> run_time_out(mode, run_time_unit) end)
  end
  defp mode_out(mode, run_time_unit) when is_number(mode) do
    run_time_out(mode, run_time_unit)
  end

  @spec extended_column_descriptors(integer) :: String.t
  defp extended_column_descriptors(label_width) do
    "\n~*s~*s~*s~*s~*s\n"
    |> :io_lib.format([-label_width, "Name", @minimum_width, "minimum",
                       @maximum_width, "maximum", @sample_size_width, "sample size",
                       @mode_width, "mode"])
    |> to_string
  end

  @spec column_descriptors(integer) :: String.t
  defp column_descriptors(label_width) do
    "\n~*s~*s~*s~*s~*s~*s\n"
    |> :io_lib.format([-label_width, "Name", @ips_width, "ips",
                       @average_width, "average",
                       @deviation_width, "deviation", @median_width, "median",
                       @percentile_width, "99th %"])
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

  @spec scenario_reports([Scenario.t], unit_per_statistic, integer)
    :: [String.t]
  defp scenario_reports(scenarios, units, label_width) do
    Enum.map(scenarios, fn(scenario) ->
      format_scenario(scenario, units, label_width)
    end)
  end

  @spec format_scenario(Scenario.t, unit_per_statistic, integer) :: String.t
  defp format_scenario(%Scenario{
                         job_name: name,
                         run_time_statistics: %Statistics{
                           average:       average,
                           ips:           ips,
                           std_dev_ratio: std_dev_ratio,
                           median:        median,
                           percentiles:   %{99 => percentile_99}
                         }
                       },
                       %{run_time: run_time_unit,
                         ips:      ips_unit,
                       }, label_width) do
    "~*s~*ts~*ts~*ts~*ts~*ts\n"
    |> :io_lib.format([
      -label_width, name,
      @ips_width, ips_out(ips, ips_unit),
      @average_width, run_time_out(average, run_time_unit),
      @deviation_width, deviation_out(std_dev_ratio),
      @median_width, run_time_out(median, run_time_unit),
      @percentile_width, run_time_out(percentile_99, run_time_unit)])
    |> to_string
  end

  defp ips_out(ips, unit) do
    Count.format({Count.scale(ips, unit), unit})
  end

  defp run_time_out(run_time, unit) do
    Duration.format({Duration.scale(run_time, unit), unit})
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
      descriptor("Comparison"),
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

  @spec descriptor(String.t) :: String.t
  defp descriptor(header_str) do
    "\n#{header_str}: \n"
  end
end
