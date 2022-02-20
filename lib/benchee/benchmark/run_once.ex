defmodule Benchee.Benchmark.RunOnce do
  @moduledoc """
  All that you need to run a function once, hooks and all.

  Used for the `pre_check` functionality as well as profiling.
  """

  alias Benchee.Benchmark.Hooks
  alias Benchee.Benchmark.Runner
  alias Benchee.Benchmark.ScenarioContext

  def run(scenario, scenario_context, collector) do
    scenario_input = Hooks.run_before_scenario(scenario, scenario_context)
    scenario_context = %ScenarioContext{scenario_context | scenario_input: scenario_input}
    _ = Runner.collect(scenario, scenario_context, collector)
    _ = Hooks.run_after_scenario(scenario, scenario_context)
    nil
  end
end
