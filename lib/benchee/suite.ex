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

    def init(suite) do
      columns = get_columns_from_suite(suite)
      {rows, count} = extract_rows_from_suite(suite)

      {:rows, %{columns: columns, count: count}, rows}
    end

    defp get_columns_from_suite(suite) do
      config_percentiles = suite.configuration.percentiles

      percentile_labels =
        Enum.map(config_percentiles, fn percentile ->
          "p_#{percentile}"
        end)

      fields_per_type =
        [
          "samples",
          "ips",
          "average",
          "maximum",
          "median",
          "minimum",
          "mode",
          "sample_size",
          "std_dev"
        ] ++ percentile_labels

      memory_fields = Enum.map(fields_per_type, fn field -> "memory_#{field}" end)
      reductions_fields = Enum.map(fields_per_type, fn field -> "reductions_#{field}" end)
      run_time_fields = Enum.map(fields_per_type, fn field -> "run_time_#{field}" end)

      List.flatten([
        "job_name",
        memory_fields,
        reductions_fields,
        run_time_fields
      ])
    end

    defp extract_rows_from_suite(suite) do
      config_percentiles = suite.configuration.percentiles

      Enum.map_reduce(suite.scenarios, 0, fn %Scenario{} = scenario, count ->
        mem_stats = get_stats_from_scenario(scenario.memory_usage_data, config_percentiles)
        reduction_stats = get_stats_from_scenario(scenario.reductions_data, config_percentiles)
        runtime_stats = get_stats_from_scenario(scenario.run_time_data, config_percentiles)

        row =
          Enum.concat([
            [scenario.job_name],
            mem_stats,
            reduction_stats,
            runtime_stats
          ])

        {row, count + 1}
      end)
    end

    defp get_stats_from_scenario(
           %CollectionData{statistics: statistics} = collection_data,
           percentiles
         ) do
      percentile_data =
        Enum.map(percentiles, fn percentile -> statistics.percentiles[percentile] end)

      Enum.concat([
        [
          collection_data.samples,
          statistics.ips,
          statistics.average,
          statistics.maximum,
          statistics.median,
          statistics.minimum,
          statistics.mode,
          statistics.sample_size,
          statistics.std_dev
        ],
        percentile_data
      ])
    end
  end
end
