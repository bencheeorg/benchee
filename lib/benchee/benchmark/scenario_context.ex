defmodule Benchee.Benchmark.ScenarioContext do
  defstruct [
    :config,
    :printer,
    :show_fast_warning,
    :run_time,
    :current_time,
    :end_time,
    num_iterations: 1
  ]

  @type t :: %__MODULE__{
    config: map,
    printer: module,
    show_fast_warning: boolean,
    run_time: pos_integer,
    current_time: pos_integer,
    end_time: pos_integer,
    num_iterations: non_neg_integer
  }
end
