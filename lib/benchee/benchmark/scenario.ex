defmodule Benchee.Benchmark.Scenario do
  defstruct [:job_name, :function, :input_name, :input, :run_times,
             :run_time_statistics, :memory_usages, :memory_usage_statistics]

  @type t :: %__MODULE__{
    job_name: binary,
    function: fun,
    input_name: binary | nil,
    input: any | nil,
    run_times: [float] | nil,
    run_time_statistics: Benchee.Statistics.t | nil,
    memory_usages: [non_neg_integer] | nil,
    memory_usage_statistics: Benchee.Statistics.t | nil
  }
end
