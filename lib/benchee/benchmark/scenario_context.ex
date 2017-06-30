defmodule Benchee.Benchmark.ScenarioContext do
  # QUESTION: I added the fast warning and run_time here pretty much just so I
  # had a consistent way of running warmups and real runs without having to have
  # additional information. It's essentially duplicating data from the config,
  # though. Is this a problem?
  defstruct [
    :config,
    :printer,
    :show_fast_warning,
    :run_time,
    :current_time,
    :end_time,
    num_iterations: 1
  ]
end
