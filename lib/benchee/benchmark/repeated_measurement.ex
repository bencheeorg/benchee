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
  # Today this is mostly only relevant on Windows & Mac OS as we have nanosecond precision on
  # Linux and we've failed to produce a measurable function call that takes less than 10 nano
  # seconds.
  #
  # That's also why this code lives in a separate module and not `Runner` - as it's rarely used
  # and clutters that code + we need a way to test it even if we can't trigger it's conditions.

  # If a function executes way too fast measurements are too unreliable and
  # with too high variance. Therefore determine an n how often it should be
  # executed in the measurement cycle.

  alias Benchee.Benchmark.{Collect, Hooks, Runner, ScenarioContext}
  alias Benchee.Scenario
  alias Benchee.Utility.ErlangVersion
  alias Benchee.Utility.RepeatN

  @minimum_execution_time 10
  @times_multiplier 10
  @nanosecond_resolution Benchee.Conversion.Duration.convert_value({1, :second}, :nanosecond)

  @spec determine_n_times(Scenario.t(), ScenarioContext.t(), boolean, module) ::
          {pos_integer, number}
  def determine_n_times(
        scenario,
        scenario_context = %ScenarioContext{system: system_info},
        print_fast_warning,
        clock_info \\ :erlang.system_info(:os_monotonic_time_source),
        collector \\ Collect.Time
      ) do
    resolution_adjustment = determine_resolution_adjustment(system_info, clock_info)

    do_determine_n_times(
      scenario,
      scenario_context,
      print_fast_warning,
      resolution_adjustment,
      collector
    )
  end

  # See ERL-1067 aka which was fixed here
  # https://erlang.org/download/otp_src_22.2.readme
  @fixed_erlang_vesion "22.2.0"
  # MacOS usually measures in micro seconds so that's the best default to return when not given
  @old_macos_value 1_000

  defp determine_resolution_adjustment(system_info, clock_info) do
    if trust_clock?(system_info) do
      # If the resolution is 1_000_000 that means microsecond, while 1_000_000_000 is nanosecond.
      # we then need to adjust our measured time by that value. I.e. if we measured "5000" here we
      # do not want to let it pass as it is essentially just "5" for our measurement purposes.
      {:ok, resolution} = Access.fetch(clock_info, :resolution)

      @nanosecond_resolution / resolution
    else
      @old_macos_value
    end
  end

  # Can't really trust the macOS clock on OTP before mentioned version, see tickets linked above
  defp trust_clock?(%{os: :macOS, erlang: erlang_version}) do
    ErlangVersion.includes_fixes_from?(erlang_version, @fixed_erlang_vesion)
  end

  # If `suite.system` wasn't populated then we'll not mistrust it as well as all others
  # (can happen if people call parts of benchee themselves without calling system first)
  defp trust_clock?(_), do: true

  defp do_determine_n_times(
         scenario,
         scenario_context = %ScenarioContext{
           num_iterations: num_iterations,
           printer: printer
         },
         print_fast_warning,
         resolution_adjustment,
         collector
       ) do
    run_time = measure_iteration(scenario, scenario_context, collector)
    resolution_adjusted_run_time = run_time / resolution_adjustment

    if resolution_adjusted_run_time >= @minimum_execution_time do
      {num_iterations, report_time(run_time, num_iterations)}
    else
      if print_fast_warning, do: printer.fast_warning()

      new_context = %ScenarioContext{
        scenario_context
        | num_iterations: num_iterations * @times_multiplier
      }

      do_determine_n_times(scenario, new_context, false, resolution_adjustment, collector)
    end
  end

  # we need to convert the time here since we measure native time to see when we have enough
  # repetitions but the first time is used in the actual samples
  defp report_time(measurement, num_iterations) do
    adjust_for_iterations(measurement, num_iterations)
  end

  defp adjust_for_iterations(measurement, 1), do: measurement
  defp adjust_for_iterations(measurement, num_iterations), do: measurement / num_iterations

  @spec collect(Scenario.t(), ScenarioContext.t(), module) :: number
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
