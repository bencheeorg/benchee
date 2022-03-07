defmodule Benchee.Benchmark.Hooks do
  @moduledoc """
  Internal module to support hooks functionality.
  """

  # Non Benchee code should not rely on this module.

  alias Benchee.Benchmark.ScenarioContext
  alias Benchee.Scenario

  @type hook_function :: (any -> any)

  @spec run_before_scenario(Scenario.t(), ScenarioContext.t()) :: any
  def run_before_scenario(
        %Scenario{
          before_scenario: local_before_scenario,
          input: input
        },
        %ScenarioContext{
          config: %{before_scenario: global_before_scenario}
        }
      ) do
    input
    |> run_before_function(global_before_scenario)
    |> run_before_function(local_before_scenario)
  end

  defp run_before_function(input, nil), do: input
  defp run_before_function(input, function), do: function.(input)

  @spec run_before_each(Scenario.t(), ScenarioContext.t()) :: any
  def run_before_each(
        %{
          before_each: local_before_each
        },
        %{
          config: %{before_each: global_before_each},
          scenario_input: input
        }
      ) do
    input
    |> run_before_function(global_before_each)
    |> run_before_function(local_before_each)
  end

  @spec run_after_each(any, Scenario.t(), ScenarioContext.t()) :: any
  def run_after_each(
        return_value,
        %{
          after_each: local_after_each
        },
        %{
          config: %{after_each: global_after_each}
        }
      ) do
    if local_after_each, do: local_after_each.(return_value)
    if global_after_each, do: global_after_each.(return_value)
  end

  @spec run_after_scenario(Scenario.t(), ScenarioContext.t()) :: any
  def run_after_scenario(
        %{
          after_scenario: local_after_scenario
        },
        %{
          config: %{after_scenario: global_after_scenario},
          scenario_input: input
        }
      ) do
    if local_after_scenario, do: local_after_scenario.(input)
    if global_after_scenario, do: global_after_scenario.(input)
  end
end
