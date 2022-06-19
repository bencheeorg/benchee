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
    # The profile tests have been too flakey due to process not being started
    some_error ->
      # credo:disable-for-next-line Credo.Check.Warning.IoInspect
      IO.inspect(some_error, label: "Error being retried:")
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

  @doc """
  Get a `:timer.sleep/1` time, that does not run into danger of triggering repeated measurements.

  `:timer.sleep/1` measures time in milliseconds. If the resolution of the native clock is in
  nanoseconds then 1 is fine (1_000_000 nanoseconds), whereas if the resolution is milliseconds or
  less it becomes hard to hit the limit we've setup in `Benchee.Benchmark.RepeatedMeasurement`,
  which is to hit at least 10 time units of measurement.

  We can do this at compile time, as the system clock should not change.

  Specifically this used on Windows CI, which for whatever reason that I do not understand
  seems to have a resolution of 100 which is... 10 milliseconds. Which is... way too little.
  """
  @clock_resolution Access.get(:erlang.system_info(:os_monotonic_time_source), :resolution)
  @milliseconds Benchee.Conversion.Duration.convert_value({1, :second}, :millisecond)
  @minimum_measured_time 10
  @min_sleep_time 1
  @safe_test_sleep_time_float max(
                                @minimum_measured_time / (@clock_resolution / @milliseconds),
                                @min_sleep_time
                              )
  @safe_test_sleep_time trunc(@safe_test_sleep_time_float)
  def sleep_safe_time do
    :timer.sleep(@safe_test_sleep_time)
  end

  def safe_sleep_time do
    @safe_test_sleep_time
  end
end
