defmodule Benchee.Benchmark.ScenarioContext do
  @moduledoc """
  This struct holds the context in which any scenario is run.
  """
  defstruct [
    :config,
    :printer,
    :current_time,
    :end_time,
    :benchmarking_function,
    num_iterations: 1
  ]

  @type t :: %__MODULE__{
          config: Benchee.Configuration.t(),
          printer: module,
          current_time: pos_integer | nil,
          end_time: pos_integer | nil,
          benchmarking_function: (-> any) | nil,
          num_iterations: pos_integer
        }
end
