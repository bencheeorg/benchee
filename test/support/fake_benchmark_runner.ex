defmodule Benchee.Test.FakeBenchmarkRunner do
  @moduledoc false

  def run_scenarios(scenarios, scenario_context) do
    send(self(), {:run_scenarios, scenarios, scenario_context})

    Enum.map(scenarios, fn scenario ->
      %{scenario | run_time_data: %{scenario.run_time_data | samples: [1.0]}}
    end)
  end
end
