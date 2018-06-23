defmodule Benchee.Benchmark.ScenarioContext do
  @moduledoc false

  # This struct holds the context in which any scenario is run.

  defstruct [
    :config,
    :printer,
    :current_time,
    :end_time,
    # before_scenario can alter the original input
    scenario_input: nil,
    num_iterations: 1,
    function_call_overhead: 0
  ]

  @type t :: %__MODULE__{
          config: Benchee.Configuration.t(),
          printer: module,
          current_time: pos_integer | nil,
          end_time: pos_integer | nil,
          scenario_input: any,
          num_iterations: pos_integer,
          function_call_overhead: pos_integer
        }
end
