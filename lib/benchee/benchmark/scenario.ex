defmodule Benchee.Benchmark.Scenario do
  @moduledoc """
  A Scenario in Benchee is a particular case of a whole benchmarking suite. That
  is the combination of a particular function to benchmark (`job_name` and
  `function`) in combination with a specific input (`input_name` and `input`).

  It then gathers all data measured for this particular combination during
  `Benchee.Benchmark.measure/3` (`run_times` and `memory_usages`),
  which are then used later in the process by `Benchee.Statistics` to compute
  the relevant statistics (`run_time_statistics` and `memory_usage_statistics`).

  `name` is the name that should be used by formatters to display scenarios as
  it potentially includes the `tag` present when loading scenarios that were
  saved before. See `display_name/1`.
  """
  defstruct [
    :name,
    :job_name,
    :function,
    :input_name,
    :input,
    :run_time_statistics,
    :memory_usage_statistics,
    run_times: [],
    memory_usages: [],
    before_each: nil,
    after_each: nil,
    before_scenario: nil,
    after_scenario: nil,
    tag: nil
  ]

  @type t :: %__MODULE__{
    name:                    String.t,
    job_name:                String.t,
    function:                fun,
    input_name:              String.t | nil,
    input:                   any | nil,
    run_times:               [float],
    run_time_statistics:     Benchee.Statistics.t | nil,
    memory_usages:           [non_neg_integer],
    memory_usage_statistics: Benchee.Statistics.t | nil,
    before_each:             fun | nil,
    after_each:              fun | nil,
    before_scenario:         fun | nil,
    after_scenario:          fun | nil,
    tag:                     String.t | nil
  }

  @doc """
  Returns the correct name to display of the given scenario data.

  In the normal case this is `job_name`, however when scenarios are loaded they
  are tagged and these tags should be shown for disambiguation.

  ## Examples

      iex> alias Benchee.Benchmark.Scenario
      iex> Scenario.display_name(%Scenario{job_name: "flat_map"})
      "flat_map"
      iex> Scenario.display_name(%Scenario{job_name: "flat_map", tag: "master"})
      "flat_map (master)"
      iex> Scenario.display_name(%{job_name: "flat_map"})
      "flat_map"
  """
  @spec display_name(t) :: String.t()
  def display_name(%{job_name: job_name, tag: nil}), do: job_name
  def display_name(%{job_name: job_name, tag: tag}), do: "#{job_name} (#{tag})"
  def display_name(%{job_name: job_name}),           do: job_name
end
