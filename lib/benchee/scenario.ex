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
  @type benchmarking_function :: (() -> any) | (any -> any)

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

      iex> alias Benchee.Scenario
      iex> Scenario.display_name(%Scenario{job_name: "flat_map"})
      "flat_map"
      iex> Scenario.display_name(%Scenario{job_name: "flat_map", tag: "main"})
      "flat_map (main)"
      iex> Scenario.display_name(%{job_name: "flat_map"})
      "flat_map"
  """
  @spec display_name(t) :: String.t()
  def display_name(%{job_name: job_name, tag: nil}), do: job_name
  def display_name(%{job_name: job_name, tag: tag}), do: "#{job_name} (#{tag})"
  def display_name(%{job_name: job_name}), do: job_name

  @doc """
  Returns `true` if data of the provided type has been fully procsessed, `false` otherwise.

  Current available types are `run_time` and `memory`. Reasons they might not have been processed
  yet are:
  * Suite wasn't configured to collect them at all
  * `Benchee.statistics/1` hasn't been called yet so that data was collected but statistics
    aren't present yet

  ## Examples

      iex> alias Benchee.Scenario
      iex> alias Benchee.Statistics
      iex> scenario = %Scenario{run_time_data: %Benchee.CollectionData{statistics: %Statistics{sample_size: 100}}}
      iex> Scenario.data_processed?(scenario, :run_time)
      true
      iex> scenario = %Scenario{memory_usage_data: %Benchee.CollectionData{statistics: %Statistics{sample_size: 1}}}
      iex> Scenario.data_processed?(scenario, :memory)
      true
      iex> scenario = %Scenario{memory_usage_data: %Benchee.CollectionData{statistics: %Statistics{sample_size: 0}}}
      iex> Scenario.data_processed?(scenario, :memory)
      false
  """
  @spec data_processed?(t, :run_time | :memory) :: boolean
  def data_processed?(scenario, :run_time) do
    scenario.run_time_data.statistics.sample_size > 0
  end

  def data_processed?(scenario, :memory) do
    scenario.memory_usage_data.statistics.sample_size > 0
  end
end
