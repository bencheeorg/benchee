defmodule Benchee.Suite do
  @moduledoc """
  Main benchee data structure that aggregates the results from every step.

  Different layers of the benchmarking rely on different data being present
  here. For instance for `Benchee.Statistics.statistics/1` to work the
  `run_times` key needs to be filled with the results from
  `Benchee.Benchmark.measure/1`.

  Formatters can then use the data to display all of the results and the
  configuration.
  """
  defstruct [
    :configuration,
    :system,
    :run_times,
    :benchmarks,
    :statistics,
    jobs: %{}
  ]

  @type optional_map :: map | nil
  @type key :: atom | String.t
  @type benchmark_function :: (() -> any) | ((any) -> any)
  @type t :: %__MODULE__{
    configuration: Benchee.Configuration.t | nil,
    system: optional_map,
    run_times: %{key => %{key => [integer]}} | nil,
    statistics: %{key => %{key => Benchee.Statistics.t}} | nil,
    jobs: %{key => benchmark_function}
  }
end

defimpl DeepMerge.Resolver, for: Benchee.Suite do
  def resolve(original, override = %{__struct__: Benchee.Suite}, resolver) do
    cleaned_override = override
                       |> Map.from_struct
                       |> Enum.reject(fn({_key, value}) -> is_nil(value) end)
                       |> Map.new

    Map.merge(original, cleaned_override, resolver)
  end
  def resolve(original, override, resolver) when is_map(override) do
    Map.merge(original, override, resolver)
  end
end
