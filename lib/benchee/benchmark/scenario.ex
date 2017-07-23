defmodule Benchee.Benchmark.Scenario do
  defstruct [
    :job_name,
    :function,
    :input_name,
    :input,
    :run_time_statistics,
    :memory_usage_statistics,
    run_times: [],
    memory_usages: []
  ]

  @type t :: %__MODULE__{
    job_name: binary,
    function: fun,
    input_name: binary | nil,
    input: any | nil,
    run_times: [float] | [],
    run_time_statistics: Benchee.Statistics.t | nil,
    memory_usages: [non_neg_integer] | [],
    memory_usage_statistics: Benchee.Statistics.t | nil
  }
end
