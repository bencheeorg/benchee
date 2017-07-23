defmodule Benchee.Benchmark.ScenarioContext do
  @moduledoc """
  This struct holds the context in which any scenario is run.
  """
  defstruct [
    :config,
    :printer,
    :current_time,
    :end_time,
    num_iterations: 1
  ]

  @type t :: %__MODULE__{
    config: Benchee.Configuration.t,
    printer: module,
    current_time: pos_integer,
    end_time: pos_integer,
    num_iterations: non_neg_integer
  }
end
