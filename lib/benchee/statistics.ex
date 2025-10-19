defmodule Benchee.Statistics do
  @moduledoc """
  Statistics related functionality that is meant to take the raw benchmark data
  and then compute statistics like the average and the standard deviation etc.

  See `statistics/1` for a breakdown of the included statistics.
  """

  alias Benchee.{CollectionData, Conversion.Duration, Scenario, Suite}
  alias Benchee.Output.ProgressPrinter

  require Integer

  defstruct [
    :average,
    :ips,
    :std_dev,
    :std_dev_ratio,
    :std_dev_ips,
    :median,
    :percentiles,
    :mode,
    :minimum,
    :maximum,
    :relative_more,
    :relative_less,
    :absolute_difference,
    :outliers,
    :lower_outlier_bound,
    :upper_outlier_bound,
    sample_size: 0
  ]

  @typedoc """
  Careful with the mode, might be multiple values, one value or nothing.😱
  """
  @type mode :: [number] | number | nil

  @typedoc """
  All the statistics `statistics/1` computes from the samples.

  This used for run times, memory and reductions. Generally with these,
  the lower the better (less run time, memory consumption or reductions).

  These values mostly correspond to their cousins in `Statistex`.

  Overview of all the statistics Benchee currently provides:

    * average - average of all the samples (the lower the better)
    * ips - iterations per second, how often can the given function be
    executed within one second, used only for run times (the higher the better)
    * std_dev - standard deviation, how much results vary among the samples
    (the higher the more the results vary)
    * std_dev_ratio - standard deviation expressed as how much it is relative to
    the average
    * std_dev_ips - the absolute standard deviation of iterations per second
    * median - when all measured times are sorted, this is the middle
    value (or average of the two middle values when the number of times is
    even). More stable than the average and somewhat more likely to be a
    typical value you see.
    * percentiles - a map of percentile ranks. These are the values below
      which x% of the samples lie. For example, 99% of samples are less than
      is a value for which 99% of the run times are less than it.
    * mode - the samples that occur the most. Often one value, but
      can be multiple values if they occur the same amount of times. If no value
      occurs at least twice, this value will be `nil`.
    * minimum - the smallest sample measured for the scenario
    * maximum - the biggest sample measured for the scenario
    * relative_more - relative to the reference (usually the fastest scenario) how much more
    was the average of this scenario. E.g. for reference at 100, this scenario 200 then it
    is 2.0.
    * relative_less - relative to the reference (usually the fastest scenario) how much less
    was the average of this scenario. E.g. for reference at 100, this scenario 200 then it
    is 0.5.
    * absolute_difference - relative to the reference (usually the fastest scenario) what is
    the difference of the averages of the scenarios. e.g. for reference at 100, this
    scenario 200 then it is 100.
    * sample_size - the number of measurements/samples taken into account for calculating statistics
    * outliers - if outlier exclusion was enabled, may include any samples of outliers that were found, empty list otherwise
    * lower_outlier_bound - value below which values are considered an outlier
    * upper_outlier_bound - value above which values are considered an outlier
  """
  @type t :: %__MODULE__{
          average: float,
          ips: float | nil,
          std_dev: float,
          std_dev_ratio: float,
          std_dev_ips: float | nil,
          median: number,
          percentiles: %{number => float},
          mode: mode,
          minimum: number,
          maximum: number,
          relative_more: float | nil | :infinity,
          relative_less: float | nil | :infinity,
          absolute_difference: float | nil,
          outliers: [number],
          lower_outlier_bound: number,
          upper_outlier_bound: number,
          sample_size: integer
        }

  @typedoc """
  The samples a `Benchee.Collect` collected to compute statistics from.
  """
  @type samples :: [number]

  @doc """
  Takes a suite with scenarios and their data samples, adds the statistics to the
  scenarios. For an overview of what the statistics mean see `t:t/0`.

  Note that this will also sort the scenarios fastest to slowest to ensure a consistent order
  of scenarios in all used formatters.

  ## Examples

      iex> scenarios = [
      ...>   %Benchee.Scenario{
      ...>     job_name: "My Job",
      ...>     run_time_data: %Benchee.CollectionData{
      ...>       samples: [200, 400, 400, 400, 500, 500, 500, 700, 900]
      ...>     },
      ...>     memory_usage_data: %Benchee.CollectionData{
      ...>       samples: [200, 400, 400, 400, 500, 500, 500, 700, 900]
      ...>     },
      ...>     input_name: "Input",
      ...>     input: "Input"
      ...>   }
      ...> ]
      ...>
      ...> suite = %Benchee.Suite{scenarios: scenarios}
      ...> statistics(suite, Benchee.Test.FakeProgressPrinter)
      %Benchee.Suite{
        scenarios: [
          %Benchee.Scenario{
            job_name: "My Job",
            input_name: "Input",
            input: "Input",
            run_time_data: %Benchee.CollectionData{
              samples: [200, 400, 400, 400, 500, 500, 500, 700, 900],
              statistics: %Benchee.Statistics{
                average: 500.0,
                ips: 2000_000.0,
                std_dev: 200.0,
                std_dev_ratio: 0.4,
                std_dev_ips: 800_000.0,
                median: 500.0,
                percentiles: %{25 => 400.0, 50 => 500.0, 75 => 600.0, 99 => 900.0},
                mode: [500, 400],
                minimum: 200,
                maximum: 900,
                sample_size: 9,
                outliers: [],
                lower_outlier_bound: 100.0,
                upper_outlier_bound: 900.0
              }
            },
            memory_usage_data: %Benchee.CollectionData{
              samples: [200, 400, 400, 400, 500, 500, 500, 700, 900],
              statistics: %Benchee.Statistics{
                average: 500.0,
                ips: nil,
                std_dev: 200.0,
                std_dev_ratio: 0.4,
                std_dev_ips: nil,
                median: 500.0,
                percentiles: %{25 => 400.0, 50 => 500.0, 75 => 600.0, 99 => 900.0},
                mode: [500, 400],
                minimum: 200,
                maximum: 900,
                sample_size: 9,
                outliers: [],
                lower_outlier_bound: 100.0,
                upper_outlier_bound: 900.0
              }
            }
          }
        ],
        system: nil
      }

  """
  @spec statistics(Suite.t()) :: Suite.t()
  def statistics(suite, printer \\ ProgressPrinter) do
    printer.calculating_statistics(suite.configuration)

    percentiles = suite.configuration.percentiles
    exclude_outliers? = suite.configuration.exclude_outliers

    update_in(suite.scenarios, fn scenarios ->
      scenario_statistics =
        compute_statistics_in_parallel(scenarios, percentiles, exclude_outliers?)

      update_scenarios_with_statistics(scenarios, scenario_statistics)
    end)
  end

  defp compute_statistics_in_parallel(scenarios, percentiles, exclude_outliers?) do
    scenarios
    |> Enum.map(fn scenario ->
      # we filter down the data here to avoid sending the input and benchmarking function to
      # the other processes
      # we send over all of the collection data as in the future (tm) we might want to already
      # provide the sample size, which this gives us a way to do that and not touch this code
      # again
      {scenario.run_time_data, scenario.memory_usage_data, scenario.reductions_data}
    end)
    # async_stream as we might run a ton of scenarios depending on the benchmark
    |> Task.async_stream(
      fn scenario_collection_data ->
        calculate_scenario_statistics(scenario_collection_data, percentiles, exclude_outliers?)
      end,
      timeout: :infinity,
      ordered: true
    )
    |> Enum.map(fn {:ok, stats} -> stats end)
  end

  defp update_scenarios_with_statistics(scenarios, scenario_statistics) do
    # we can zip them as they retained order
    scenarios
    |> Enum.zip(scenario_statistics)
    |> Enum.map(fn {%Scenario{
                      run_time_data: %CollectionData{},
                      memory_usage_data: %CollectionData{},
                      reductions_data: %CollectionData{}
                    } = scenario, {run_time_stats, memory_stats, reductions_stats}} ->
      %Scenario{
        scenario
        | run_time_data: %CollectionData{
            scenario.run_time_data
            | statistics: run_time_stats
          },
          memory_usage_data: %CollectionData{
            scenario.memory_usage_data
            | statistics: memory_stats
          },
          reductions_data: %CollectionData{
            scenario.reductions_data
            | statistics: reductions_stats
          }
      }
    end)
  end

  defp calculate_scenario_statistics(
         {run_time_data, memory_data, reductions_data},
         percentiles,
         exclude_outliers?
       ) do
    run_time_stats =
      run_time_data.samples
      |> calculate_statistics(percentiles, exclude_outliers?)
      |> add_ips

    memory_stats = calculate_statistics(memory_data.samples, percentiles, exclude_outliers?)

    reductions_stats =
      calculate_statistics(reductions_data.samples, percentiles, exclude_outliers?)

    {run_time_stats, memory_stats, reductions_stats}
  end

  defp calculate_statistics([], _, _) do
    %__MODULE__{
      sample_size: 0
    }
  end

  defp calculate_statistics(samples, percentiles, exclude_outliers?) do
    samples
    |> Statistex.statistics(percentiles: percentiles, exclude_outliers: exclude_outliers?)
    |> convert_from_statistex
  end

  # It might seem silly to maintain and map statistex to our own struct,
  # but this gives benchee more control  and makes it safer to upgrade and change.
  # Also, we don't expose changes in statistex versions automatically to plugins.
  #
  # As an example right now it's being discussed in statistex to add an `m2` statistic that holds
  # no value for benchee (as it's ony used to calculate variance).
  #
  # We also manually add `ips` related stats (see `add_ips/1`) so differences are sufficient.
  defp convert_from_statistex(statistex_statistics) do
    %__MODULE__{
      average: statistex_statistics.average,
      std_dev: statistex_statistics.standard_deviation,
      std_dev_ratio: statistex_statistics.standard_deviation_ratio,
      median: statistex_statistics.median,
      percentiles: statistex_statistics.percentiles,
      mode: statistex_statistics.mode,
      minimum: statistex_statistics.minimum,
      maximum: statistex_statistics.maximum,
      sample_size: statistex_statistics.sample_size,
      outliers: statistex_statistics.outliers,
      lower_outlier_bound: statistex_statistics.lower_outlier_bound,
      upper_outlier_bound: statistex_statistics.upper_outlier_bound
    }
  end

  defp add_ips(statistics = %__MODULE__{sample_size: 0}), do: statistics
  defp add_ips(statistics = %__MODULE__{average: +0.0}), do: statistics

  defp add_ips(statistics = %__MODULE__{}) do
    ips = Duration.convert_value({1, :second}, :nanosecond) / statistics.average
    standard_dev_ips = ips * statistics.std_dev_ratio

    %__MODULE__{
      statistics
      | ips: ips,
        std_dev_ips: standard_dev_ips
    }
  end
end
