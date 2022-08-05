defmodule Benchee.Suite do
  @moduledoc """
  Main Benchee data structure that aggregates the results from every step.

  Different layers of the benchmarking rely on different data being present
  here. For instance for `Benchee.Statistics.statistics/1` to work the
  `run_time_data` key of each scenario needs to be filled with the samples
  collected by `Benchee.Benchmark.collect/1`.

  Formatters can then use the data to display all of the results and the
  configuration.
  """
  defstruct [
    :system,
    configuration: %Benchee.Configuration{},
    scenarios: []
  ]

  @typedoc """
  Valid key for either input or benchmarking job names.
  """
  @type key :: String.t() | atom

  @typedoc """
  The main suite consisting of the configuration data, information about the system and most
  importantly a list of `t:Benchee.Scenario.t/0`.
  """
  @type t :: %__MODULE__{
          configuration: Benchee.Configuration.t() | nil,
          system: map | nil,
          scenarios: [] | [Benchee.Scenario.t()]
        }
end

defimpl DeepMerge.Resolver, for: Benchee.Suite do
  def resolve(original, override = %Benchee.Suite{}, resolver) do
    cleaned_override =
      override
      |> Map.from_struct()
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    Map.merge(original, cleaned_override, resolver)
  end

  def resolve(original, override, resolver) when is_map(override) do
    Map.merge(original, override, resolver)
  end
end

if Code.ensure_loaded?(Table.Reader) do
  defimpl Table.Reader, for: Benchee.Suite do
    alias Benchee.CollectionData
    alias Benchee.Scenario

    def init(suite_results) do
      summarized_results = extract_rows_from_suite(suite_results)

      {:rows, %{columns: summarized_results.columns, count: summarized_results.num_rows},
       summarized_results.rows}
    end

    defp extract_rows_from_suite(suite_results) do
      config_percentiles = suite_results.configuration.percentiles

      percentile_labels =
        Enum.map(config_percentiles, fn percentile ->
          "p_#{percentile}"
        end)

      fields_per_type =
        List.flatten([
          "samples",
          "ips",
          "average",
          "maximum",
          "median",
          "minimum",
          "mode",
          percentile_labels,
          "sample_size",
          "std_dev"
        ])

      memory_fields = Enum.map(fields_per_type, fn field -> "memory_#{field}" end)
      reductions_fields = Enum.map(fields_per_type, fn field -> "reductions_#{field}" end)
      run_time_fields = Enum.map(fields_per_type, fn field -> "run_time_#{field}" end)

      columns =
        List.flatten([
          "job_name",
          memory_fields,
          reductions_fields,
          run_time_fields
        ])

      Enum.reduce(
        suite_results.scenarios,
        %{columns: columns, num_rows: 0, rows: []},
        fn %Scenario{} = scenario, acc ->
          mem_stats = get_stats_from_scenario(scenario.memory_usage_data, config_percentiles)
          reduction_stats = get_stats_from_scenario(scenario.reductions_data, config_percentiles)
          runtime_stats = get_stats_from_scenario(scenario.run_time_data, config_percentiles)
          new_row = [scenario.job_name] ++ mem_stats ++ reduction_stats ++ runtime_stats

          acc
          |> Map.update!(:num_rows, &(&1 + 1))
          |> Map.update!(:rows, &[new_row | &1])
        end
      )
      |> Map.update!(:rows, &Enum.reverse/1)
    end

    defp get_stats_from_scenario(
           %CollectionData{statistics: statistics} = collection_data,
           percentiles
         ) do
      percentile_data =
        Enum.map(percentiles, fn percentile ->
          if statistics.percentiles do
            Map.get(statistics.percentiles, percentile)
          else
            nil
          end
        end)

      [collection_data.samples] ++
        List.flatten([
          statistics.ips,
          statistics.average,
          statistics.maximum,
          statistics.median,
          statistics.minimum,
          statistics.mode,
          percentile_data,
          statistics.sample_size,
          statistics.std_dev
        ])
    end
  end
end
