defmodule Benchee.Scenario do
  @moduledoc """
  Core data structure representing one particular case (combination of function and input).

  Represents the combination of a particular function to benchmark (also called "job" defined
  by `job_name` and `function`) in combination with a specific input (`input_name` and `input`).
  When no input is given, the combined value is representative of "no input".

  A scenario then further gathers all data collected for this particular combination during
  `Benchee.Benchmark.collect/3`, which are then used later in the process by `Benchee.Statistics`
  to compute the relevant statistics which are then also added to the scenario.
  It is the home of the aggregated knowledge regarding this particular case/scenario.

  `name` is the name that should be used by formatters to display scenarios as
  it potentially includes the `tag` present when loading scenarios that were
  saved before. See `display_name/1`.
  """

  alias Benchee.Benchmark.Hooks
  alias Benchee.CollectionData

  defstruct [
    :name,
    :job_name,
    :function,
    :input_name,
    :input,
    :before_each,
    :after_each,
    :before_scenario,
    :after_scenario,
    :tag,
    run_time_data: %CollectionData{},
    memory_usage_data: %CollectionData{},
    reductions_data: %CollectionData{}
  ]

  @typedoc """
  The main function executed while benchmarking.

  No arguments if no inputs are used, one argument if inputs are used.
  """
  @type benchmarking_function :: (-> any) | (any -> any)

  @typedoc """
  What shall be benchmarked, mostly a function but can contain options.

  Options are there for hooks (`after_each`, `before_each` etc.)
  """
  @type to_benchmark :: benchmarking_function() | {benchmarking_function(), keyword()}

  @typedoc """
  All the data collected for a scenario (combination of function and input)

  Among all the data required to execute the scenario (function, input, all the hooks aka
  after_*/before_*), data needed to display (name, job_name, input_name, tag) and of course
  run_time_data and memory_data with all the samples and computed statistics.
  """
  @type t :: %__MODULE__{
          name: String.t(),
          job_name: String.t(),
          function: benchmarking_function,
          input_name: String.t() | nil,
          input: any | nil,
          run_time_data: CollectionData.t(),
          memory_usage_data: CollectionData.t(),
          reductions_data: CollectionData.t(),
          before_each: Hooks.hook_function() | nil,
          after_each: Hooks.hook_function() | nil,
          before_scenario: Hooks.hook_function() | nil,
          after_scenario: Hooks.hook_function() | nil,
          tag: String.t() | nil
        }

  @doc """
  Returns the correct name to display of the given scenario data.

  In the normal case this is `job_name`, however when scenarios are loaded they
  are tagged and these tags should be shown for disambiguation.

  ## Examples

      iex> display_name(%Benchee.Scenario{job_name: "flat_map"})
      "flat_map"

      iex> display_name(%Benchee.Scenario{job_name: "flat_map", tag: "main"})
      "flat_map (main)"

      iex> display_name(%{job_name: "flat_map"})
      "flat_map"
  """
  @spec display_name(t) :: String.t()
  def display_name(%{job_name: job_name, tag: nil}), do: job_name
  def display_name(%{job_name: job_name, tag: tag}), do: "#{job_name} (#{tag})"
  def display_name(%{job_name: job_name}), do: job_name

  @doc """
  Returns the different measurement types supported.


  ## Examples

      iex> measurement_types()
      [:run_time, :memory, :reductions]
  """
  @spec measurement_types :: [:memory | :reductions | :run_time, ...]
  def measurement_types, do: [:run_time, :memory, :reductions]

  @doc """
  Given the measurement type name given by `measurement_types/0`, get the associated data.

  Raises if no correct measurement type was specified.

  ## Examples

      iex> scenario = %Benchee.Scenario{run_time_data: %Benchee.CollectionData{statistics: %Benchee.Statistics{sample_size: 1}}}
      iex> measurement_data(scenario, :run_time)
      %Benchee.CollectionData{statistics: %Benchee.Statistics{sample_size: 1}}

      iex> scenario = %Benchee.Scenario{memory_usage_data: %Benchee.CollectionData{statistics: %Benchee.Statistics{sample_size: 2}}}
      iex> measurement_data(scenario, :memory)
      %Benchee.CollectionData{statistics: %Benchee.Statistics{sample_size: 2}}

      iex> scenario = %Benchee.Scenario{reductions_data: %Benchee.CollectionData{statistics: %Benchee.Statistics{sample_size: 3}}}
      iex> measurement_data(scenario, :reductions)
      %Benchee.CollectionData{statistics: %Benchee.Statistics{sample_size: 3}}

      iex> measurement_data(%Benchee.Scenario{}, :memory)
      %Benchee.CollectionData{}

      iex> measurement_data(%Benchee.Scenario{}, :invalid)
      ** (FunctionClauseError) no function clause matching in Benchee.Scenario.measurement_data/2
  """
  @spec measurement_data(t, :memory | :reductions | :run_time) :: CollectionData.t()
  # Arguably this access is OO-ish/not great. However, with the incosistency we have in naming
  # between the scenario struct fields and the measurement types this should be good/covnenient.
  # Technically, we could/should move to a map structure from "measurement_type" to collection
  # data but it's probably not worth breaking compatibility for right now.
  def measurement_data(scenario, measurement_type)
  def measurement_data(scenario, :run_time), do: scenario.run_time_data
  def measurement_data(scenario, :memory), do: scenario.memory_usage_data
  def measurement_data(scenario, :reductions), do: scenario.reductions_data

  @doc """
  Returns `true` if data of the provided type has been fully procsessed, `false` otherwise.

  Current available types are `run_time` and `memory`. Reasons they might not have been processed
  yet are:
  * Suite wasn't configured to collect them at all
  * `Benchee.statistics/1` hasn't been called yet so that data was collected but statistics
    aren't present yet

  ## Examples

      iex> scenario = %Benchee.Scenario{run_time_data: %Benchee.CollectionData{statistics: %Benchee.Statistics{sample_size: 100}}}
      iex> data_processed?(scenario, :run_time)
      true

      iex> scenario = %Benchee.Scenario{memory_usage_data: %Benchee.CollectionData{statistics: %Benchee.Statistics{sample_size: 1}}}
      iex> data_processed?(scenario, :memory)
      true

      iex> scenario = %Benchee.Scenario{reductions_data: %Benchee.CollectionData{statistics: %Benchee.Statistics{sample_size: 1}}}
      iex> data_processed?(scenario, :reductions)
      true

      iex> scenario = %Benchee.Scenario{memory_usage_data: %Benchee.CollectionData{statistics: %Benchee.Statistics{sample_size: 0}}}
      iex> data_processed?(scenario, :memory)
      false
  """
  @spec data_processed?(t, :run_time | :memory) :: boolean
  def data_processed?(scenario, :run_time) do
    scenario.run_time_data.statistics.sample_size > 0
  end

  def data_processed?(scenario, :memory) do
    scenario.memory_usage_data.statistics.sample_size > 0
  end

  def data_processed?(scenario, :reductions) do
    scenario.reductions_data.statistics.sample_size > 0
  end
end
