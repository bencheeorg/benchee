defmodule Benchee.TestHelpers do
  @moduledoc false

  import ExUnit.Assertions

  @default_retries 10

  # retry tests that are doing actual benchmarking and are flaky
  # on overloaded and/or slower systems
  def retrying(asserting_function, n \\ @default_retries)

  def retrying(asserting_function, 1) do
    asserting_function.()
  end

  def retrying(asserting_function, n) do
    asserting_function.()
  rescue
    ExUnit.AssertionError ->
      retrying(asserting_function, n - 1)
  end

  def assert_received_exactly(expected) do
    Enum.each(expected, fn message -> assert_received ^message end)

    expected
    |> Enum.uniq()
    |> Enum.each(fn message -> refute_received(^message) end)
  end

  def suite_without_scenario_tags(suite) do
    scenarios =
      Enum.map(suite.scenarios, fn scenario ->
        %Benchee.Scenario{scenario | tag: nil, name: scenario.job_name}
      end)

    %Benchee.Suite{suite | scenarios: scenarios}
  end
end
