defmodule Bencheee.Benchmark.RepeatedMeasurementTest.FakeCollector do
  @behaviour Benchee.Benchmark.Collect

  def collect(function) do
    value = function.()
    time = Process.get(:test_measurement_time, 5)
    next_value = time * 10

    Process.put(:test_measurement_time, next_value)

    {time, value}
  end
end

defmodule Bencheee.Benchmark.RepeatedMeasurementTest do
  use ExUnit.Case

  import Benchee.Benchmark.RepeatedMeasurement
  alias Benchee.Benchmark.{Scenario, ScenarioContext}
  alias Benchee.Test.FakeBenchmarkPrinter
  alias Bencheee.Benchmark.RepeatedMeasurementTest.FakeCollector

  @no_input Benchee.Benchmark.no_input()
  @scenario_context %ScenarioContext{
    num_iterations: 1,
    printer: FakeBenchmarkPrinter,
    config: %Benchee.Configuration{},
    scenario_input: @no_input
  }

  describe ".determine_n_times/4" do
    test "it repeats the function calls until a suitable time is reached" do
      function = fn -> send(self(), :called) end
      scenario = %Scenario{function: function}
      {num_iterations, time} = determine_n_times(scenario, @scenario_context, false, FakeCollector)

      assert num_iterations == 10
      # 50 adjusted by the 10 iteration factor
      assert time == 5

      # 1 initial + 10 more after repeat
      assert_received_exactly_n_times(:called, 11)
    end

    test "doesn't do repetitions if the time is small enough from the get go" do
      function = fn -> send(self(), :called) end
      scenario = %Scenario{function: function}
      Process.put(:test_measurement_time, 10)

      {num_iterations, time} = determine_n_times(scenario, @scenario_context, false, FakeCollector)

      assert num_iterations == 1
      assert time == 10

      # 1 initial + 10 more after repeat
      assert_received_exactly_n_times(:called, 1)
    end
  end

  describe "collect/3" do
    test "scales reported times approproately" do
      scenario_context = %ScenarioContext{
        @scenario_context
        | num_iterations: 10
      }

      scenario = %Scenario{
        input: @no_input,
        function: fn -> 42 end
      }

      Process.put(:test_measurement_time, 50)

      time = collect(scenario, scenario_context, FakeCollector)

      assert time == 5
    end

    test "calls hooks appropriately even with multiple iterations" do
      num_iterations = 10

      scenario_context = %ScenarioContext{
        @scenario_context
        | num_iterations: num_iterations,
          config: %Benchee.Configuration{
            before_each: fn _ ->
              send(self(), :global_before)
              @no_input
            end,
            after_each: fn _ -> send(self(), :global_after) end
          }
      }

      scenario = %Scenario{
        input: @no_input,
        function: fn -> send(self(), :called) end,
        before_each: fn _ ->
          send(self(), :local_before)
          @no_input
        end,
        after_each: fn _ -> send(self(), :local_after) end
      }

      Process.put(:test_measurement_time, 50)

      time = collect(scenario, scenario_context, FakeCollector)

      assert time == 5

      expected_messages = [:global_before, :local_before, :called, :local_after, :global_after]

      Enum.each(expected_messages, fn message ->
        assert_received_exactly_n_times(message, num_iterations)
      end)
    end
  end

  defp assert_received_exactly_n_times(message, count) do
    Enum.each(1..count, fn _ -> assert_received ^message end)

    refute_received ^message
  end
end
