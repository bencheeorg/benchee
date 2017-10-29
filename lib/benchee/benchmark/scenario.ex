defmodule Benchee.Benchmark.Scenario do
  @moduledoc """
  A Scenario in Benchee is a particular case of a whole benchmarking suite. That
  is the combination of a particular function to benchmark (`job_name` and
  `function`) in combination with a specific input (`input_name` and `input`).

  It then gathers all data measured for this particular combination during
  `Benchee.Benchmark.measure/3` (`run_times` and `memory_usages`),
  which are then used later in the process by `Benchee.Statistics` to compute
  the relevant statistics (`run_time_statistics` and `memory_usage_statistics`).
  """
  defstruct [
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
    after_scenario: nil
  ]

  @type t :: %__MODULE__{
    job_name: binary,
    function: fun,
    input_name: binary | nil,
    input: any | nil,
    run_times: [float],
    run_time_statistics: Benchee.Statistics.t | nil,
    memory_usages: [non_neg_integer],
    memory_usage_statistics: Benchee.Statistics.t | nil,
    before_each: fun | nil,
    after_each: fun | nil,
    before_scenario: fun | nil,
    after_scenario: fun | nil
  }
end
