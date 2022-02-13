defmodule Bencheee.Benchmark.RepeatedMeasurementTest.FakeCollector do
  @behaviour Benchee.Benchmark.Collect

  def collect(function) do
    value = function.()
    time = Process.get(:test_measurement_time)
    next_value = time * 10

    Process.put(:test_measurement_time, next_value)

    {time, value}
  end
end

defmodule Bencheee.Benchmark.RepeatedMeasurementTest do
  use ExUnit.Case, async: true

  import Benchee.Benchmark.RepeatedMeasurement
  alias Benchee.Benchmark.ScenarioContext
  alias Benchee.Scenario
  alias Benchee.Test.FakeBenchmarkPrinter
  alias Bencheee.Benchmark.RepeatedMeasurementTest.FakeCollector

  @good_system_info %{erlang: "24.0.2"}
  @macos_fixed_system_info %{os: :macOS, erlang: "22.2"}
  @macos_broken_system_info %{os: :macOS, erlang: "22.1.34"}

  @no_input Benchee.Benchmark.no_input()
  @scenario_context %ScenarioContext{
    num_iterations: 1,
    printer: FakeBenchmarkPrinter,
    config: %Benchee.Configuration{},
    scenario_input: @no_input,
    system: @good_system_info
  }

  # Linux (mostly)
  @nano_second_accuracy_clock [
    resolution: Benchee.Conversion.Duration.convert_value({1, :second}, :nanosecond)
  ]

  # MacOS (mostly, it seems)
  @micro_second_accuracy_clock [
    resolution: Benchee.Conversion.Duration.convert_value({1, :second}, :microsecond)
  ]

  describe ".determine_n_times/4" do
    test "it repeats the function calls until a suitable time is reached" do
      function = fn -> send(self(), :called) end
      scenario = %Scenario{function: function}
      function_run_time = 5
      Process.put(:test_measurement_time, function_run_time)

      {num_iterations, time} =
        determine_n_times(
          scenario,
          @scenario_context,
          false,
          @nano_second_accuracy_clock,
          FakeCollector
        )

      assert num_iterations == 10

      # 50 adjusted by the 10 iteration factor
      assert_in_delta time, function_run_time, 1

      # 1 initial + 10 more after repeat
      assert_received_exactly_n_times(:called, 11)
    end

    # https://github.com/bencheeorg/benchee/issues/313
    test "it repeats the function calls until a suitable time is reached even with micro second clocks" do
      function = fn -> send(self(), :called) end
      scenario = %Scenario{function: function}

      function_run_time = 1000
      Process.put(:test_measurement_time, function_run_time)

      {num_iterations, time} =
        determine_n_times(
          scenario,
          @scenario_context,
          false,
          @micro_second_accuracy_clock,
          FakeCollector
        )

      assert num_iterations == 10

      assert_in_delta time, function_run_time, 1

      # 1 initial + 10 more after repeat
      assert_received_exactly_n_times(:called, 11)
    end

    test "it repeats the function calls even more times to reach a doable time" do
      function = fn -> send(self(), :called) end
      scenario = %Scenario{function: function}

      function_run_time = 10
      Process.put(:test_measurement_time, function_run_time)

      {num_iterations, time} =
        determine_n_times(
          scenario,
          @scenario_context,
          false,
          @micro_second_accuracy_clock,
          FakeCollector
        )

      assert num_iterations == 1000

      assert_in_delta time, function_run_time, 1

      # 1 initial + 10 + 100 + 1000
      assert_received_exactly_n_times(:called, 1111)
    end

    test "doesn't do repetitions if the time is small enough from the get go" do
      function = fn -> send(self(), :called) end
      scenario = %Scenario{function: function}
      function_time = 10
      Process.put(:test_measurement_time, function_time)

      {num_iterations, time} =
        determine_n_times(
          scenario,
          @scenario_context,
          false,
          @nano_second_accuracy_clock,
          FakeCollector
        )

      assert num_iterations == 1

      assert_in_delta time, function_time, 1

      # 1 initial + 10 more after repeat
      assert_received_exactly_n_times(:called, 1)
    end

    test "trusts the clock if no system information is present" do
      function = fn -> send(self(), :called) end
      scenario = %Scenario{function: function}
      function_run_time = 100
      Process.put(:test_measurement_time, function_run_time)

      {num_iterations, time} =
        determine_n_times(
          scenario,
          %{@scenario_context | system: nil},
          false,
          @nano_second_accuracy_clock,
          FakeCollector
        )

      assert num_iterations == 1
      assert_in_delta time, function_run_time, 1
      assert_received_exactly_n_times(:called, 1)
    end

    test "trusts the clock on a good system" do
      function = fn -> send(self(), :called) end
      scenario = %Scenario{function: function}
      function_run_time = 100
      Process.put(:test_measurement_time, function_run_time)

      {num_iterations, time} =
        determine_n_times(
          scenario,
          %{@scenario_context | system: @good_system_info},
          false,
          @nano_second_accuracy_clock,
          FakeCollector
        )

      assert num_iterations == 1
      assert_in_delta time, function_run_time, 1
      assert_received_exactly_n_times(:called, 1)
    end

    test "trusts the clock on macOS but with a fixed OTP version" do
      function = fn -> send(self(), :called) end
      scenario = %Scenario{function: function}
      function_run_time = 100
      Process.put(:test_measurement_time, function_run_time)

      {num_iterations, time} =
        determine_n_times(
          scenario,
          %{@scenario_context | system: @macos_fixed_system_info},
          false,
          @nano_second_accuracy_clock,
          FakeCollector
        )

      assert num_iterations == 1
      assert_in_delta time, function_run_time, 1
      assert_received_exactly_n_times(:called, 1)
    end

    test "does not trust the macOS clock on a broken OTP version, repeating the calls assuming milliseconds" do
      function = fn -> send(self(), :called) end
      scenario = %Scenario{function: function}
      function_run_time = 100
      Process.put(:test_measurement_time, function_run_time)

      {num_iterations, time} =
        determine_n_times(
          scenario,
          %{@scenario_context | system: @macos_broken_system_info},
          false,
          @nano_second_accuracy_clock,
          FakeCollector
        )

      assert num_iterations == 100
      assert_in_delta time, function_run_time, 1
      assert_received_exactly_n_times(:called, 111)
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
