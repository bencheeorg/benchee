defmodule Benchee.Benchmark.RepeatedMeasurement do
  @moduledoc false

  # This module is an internal implementation detail, and should absolutely not be relied upon
  # from external clients.
  #
  # It is used when we can't conduct measurements precise enough with our measurement precision.
  # I.e. we can measure in microseconds but we measure a function call to take 1 microsecond then
  # most measurements will either be 1 or 2 microseconds which won't give us great results.
  # Instead we repeat the function call n times until we measure at least ~10 (time unit) so
  # that the difference between measurements can at least be ~10%.
  #
  # Today this is mostly only relevant on Windows as we have nanosecond precision on Linux and
  # Mac OS and we've failed to produce a measurable function call that takes less than 10 nano
  # seconds.
  #
  # That's also why this code lives in a separate module and not `Runner` - as it's rarely used
  # and clutters that code + we need a way to test it even if we can't trigger it's conditions.

  # If a function executes way too fast measurements are too unreliable and
  # with too high variance. Therefore determine an n how often it should be
  # executed in the measurement cycle.

  alias Benchee.Benchmark.{Collect, Hooks, Runner, ScenarioContext}
  alias Benchee.Scenario
  alias Benchee.Utility.RepeatN

  @minimum_execution_time 10
  @times_multiplier 10
  def determine_n_times(
        scenario,
        scenario_context = %ScenarioContext{
          num_iterations: num_iterations,
          printer: printer
        },
        fast_warning,
        collector \\ Collect.NativeTime
      ) do
    run_time = measure_iteration(scenario, scenario_context, collector)

    if run_time >= @minimum_execution_time do
      {num_iterations, report_time(run_time, num_iterations)}
    else
      if fast_warning, do: printer.fast_warning()

      new_context = %ScenarioContext{
        scenario_context
        | num_iterations: num_iterations * @times_multiplier
      }

      determine_n_times(scenario, new_context, false, collector)
    end
  end

  # we need to convert the time here since we measure native time to see when we have enough
  # repetitions but the first time is used in the actual samples
  defp report_time(measurement, num_iterations) do
    measurement
    |> :erlang.convert_time_unit(:native, :nanosecond)
    |> adjust_for_iterations(num_iterations)
  end

  defp adjust_for_iterations(measurement, 1), do: measurement
  defp adjust_for_iterations(measurement, num_iterations), do: measurement / num_iterations

  def collect(
        scenario,
        scenario_context = %ScenarioContext{
          num_iterations: num_iterations
        },
        collector
      ) do
    measurement = measure_iteration(scenario, scenario_context, collector)

    adjust_for_iterations(measurement, num_iterations)
  end

  defp measure_iteration(
         scenario,
         scenario_context = %ScenarioContext{
           num_iterations: 1
         },
         collector
       ) do
    Runner.collect(scenario, scenario_context, collector)
  end

  defp measure_iteration(
         scenario,
         scenario_context = %ScenarioContext{
           num_iterations: iterations
         },
         collector
       )
       when iterations > 1 do
    # When we have more than one iteration, then the repetition and calling
    # of hooks is already included in the function, for reference/reasoning see
    # `build_benchmarking_function/2`
    function = build_benchmarking_function(scenario, scenario_context)

    {measurement, _return_value} = collector.collect(function)

    measurement
  end

  # Builds the appropriate function to benchmark. Takes into account the
  # combinations of the following cases:
  #
  # * an input is specified - creates a 0-argument function calling the original
  #   function with that input
  # * number of iterations - when there's more than one iteration we repeat the
  #   benchmarking function during execution and measure the the total run time.
  #   We only run multiple iterations if a function is so fast that we can't
  #   accurately measure it in one go. Hence, we can't split up the function
  #   execution and hooks anymore and sadly we also measure the time of the
  #   hooks.
  defp build_benchmarking_function(
         %Scenario{
           function: function,
           before_each: nil,
           after_each: nil
         },
         %ScenarioContext{
           num_iterations: iterations,
           scenario_input: input,
           config: %{after_each: nil, before_each: nil}
         }
       )
       when iterations > 1 do
    main = Runner.main_function(function, input)
    # with no before/after each we can safely omit them and don't get the hit
    # on run time measurements (See PR discussions for this for more info #127)
    fn -> RepeatN.repeat_n(main, iterations) end
  end

  defp build_benchmarking_function(
         scenario = %Scenario{function: function},
         scenario_context = %ScenarioContext{num_iterations: iterations}
       )
       when iterations > 1 do
    fn ->
      RepeatN.repeat_n(
        fn ->
          new_input = Hooks.run_before_each(scenario, scenario_context)
          main = Runner.main_function(function, new_input)
          return_value = main.()
          Hooks.run_after_each(return_value, scenario, scenario_context)
        end,
        iterations
      )
    end
  end
end
