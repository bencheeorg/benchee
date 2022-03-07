defmodule Benchee.Benchmark.ScenarioContext do
  @moduledoc """
  Internal struct the runner & related modules deal with to run a scenario.

  Practically bundles information the runner needs to be aware of while running
  a scenario such as the current_time, end_time, printer, input, function call
  overhead etc.
  """

  # This struct holds the context in which any scenario is run.

  defstruct [
    :config,
    :printer,
    :system,
    :current_time,
    :end_time,
    # before_scenario can alter the original input
    :scenario_input,
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
          function_call_overhead: non_neg_integer
        }
end
