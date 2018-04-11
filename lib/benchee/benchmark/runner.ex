defmodule Benchee.Benchmark.Runner do
  @moduledoc """
  This module actually runs our benchmark scenarios, adding information about
  run time and memory usage to each scenario.
  """

  alias Benchee.Benchmark
  alias Benchee.Benchmark.{Scenario, ScenarioContext, Measure}
  alias Benchee.Utility.{RepeatN, Parallel}
  alias Benchee.Configuration

  @doc """
  Executes the benchmarks defined before by first running the defined functions
  for `warmup` time without gathering results and them running them for `time`
  gathering their run times.

  This means the total run time of a single benchmarking scenario is warmup +
  time.

  Warmup is usually important for run times with JIT but it seems to have some
  effect on the BEAM as well.

  There will be `parallel` processes spawned executing the benchmark job in
  parallel.
  """
  @spec run_scenarios([Scenario.t()], ScenarioContext.t()) :: [Scenario.t()]
  def run_scenarios(scenarios, scenario_context) do
    Enum.each(scenarios, fn scenario -> pre_check(scenario, scenario_context) end)
    Enum.map(scenarios, fn scenario -> parallel_benchmark(scenario, scenario_context) end)
  end

  # This will run the given scenario exactly once, including the before and
  # after hooks, to ensure the function can execute without raising an error.
  defp pre_check(scenario, scenario_context = %ScenarioContext{config: %{pre_check: true}}) do
    scenario_input = run_before_scenario(scenario, scenario_context)
    scenario_context = %ScenarioContext{scenario_context | scenario_input: scenario_input}
    _ = measure_iteration(scenario, scenario_context, Measure.Time)
    _ = run_after_scenario(scenario, scenario_context)
    nil
  end

  defp pre_check(_, _), do: nil

  defp parallel_benchmark(
         scenario = %Scenario{job_name: job_name, input_name: input_name},
         scenario_context = %ScenarioContext{
           printer: printer,
           config: config
         }
       ) do
    printer.benchmarking(job_name, input_name, config)

    config
    |> measure_scenario_parallel(scenario, scenario_context)
    |> add_measurements_to_scenario(scenario)
  end

  defp measure_scenario_parallel(config, scenario, scenario_context) do
    1..config.parallel
    |> Parallel.map(fn _ -> measure_scenario(scenario, scenario_context) end)
  end

  defp add_measurements_to_scenario(measurements, scenario) do
    run_times = Enum.flat_map(measurements, fn {run_times, _} -> run_times end)
    memory_usages = Enum.flat_map(measurements, fn {_, memory_usages} -> memory_usages end)

    %Scenario{scenario | run_times: run_times, memory_usages: memory_usages}
  end

  defp measure_scenario(scenario, scenario_context) do
    scenario_input = run_before_scenario(scenario, scenario_context)
    scenario_context = %ScenarioContext{scenario_context | scenario_input: scenario_input}
    _ = run_warmup(scenario, scenario_context)
    runtimes = run_runtime_benchmark(scenario, scenario_context)
    memory_usages = run_memory_benchmark(scenario, scenario_context)
    run_after_scenario(scenario, scenario_context)

    {runtimes, memory_usages}
  end

  defp run_before_scenario(
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

  defp run_warmup(
         scenario,
         scenario_context = %ScenarioContext{
           config: %Configuration{warmup: warmup}
         }
       ) do
    measure_runtimes(scenario, scenario_context, warmup, false)
  end

  defp run_runtime_benchmark(
         scenario,
         scenario_context = %ScenarioContext{
           config: %Configuration{
             time: run_time,
             print: %{fast_warning: fast_warning}
           }
         }
       ) do
    measure_runtimes(scenario, scenario_context, run_time, fast_warning)
  end

  defp run_memory_benchmark(_, %ScenarioContext{config: %{memory_time: 0}}) do
    []
  end
  defp run_memory_benchmark(
         scenario,
         scenario_context = %ScenarioContext{
           config: %Configuration{
             memory_time: memory_time
           }
         }
       ) do

    end_time = current_time() + memory_time

    new_context = %ScenarioContext{
      scenario_context
      | current_time: current_time(),
        end_time: end_time
    }

    do_benchmark(scenario, new_context, Measure.Memory, [])
  end

  defp run_after_scenario(
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

  defp measure_runtimes(scenario, context, run_time, fast_warning)
  defp measure_runtimes(_, _, 0, _), do: []

  defp measure_runtimes(scenario, scenario_context, run_time, fast_warning) do
    end_time = current_time() + run_time
    :erlang.garbage_collect()

    {num_iterations, initial_run_time} =
      determine_n_times(scenario, scenario_context, fast_warning)

    new_context = %ScenarioContext{
      scenario_context
      | current_time: current_time(),
        end_time: end_time,
        num_iterations: num_iterations
    }

    do_benchmark(scenario, new_context, Measure.Time, [initial_run_time])
  end

  defp current_time, do: :erlang.system_time(:micro_seconds)

  # If a function executes way too fast measurements are too unreliable and
  # with too high variance. Therefore determine an n how often it should be
  # executed in the measurement cycle.
  @minimum_execution_time 10
  @times_multiplier 10
  defp determine_n_times(
         scenario,
         scenario_context = %ScenarioContext{
           num_iterations: num_iterations,
           printer: printer
         },
         fast_warning
       ) do
    run_time = measure_iteration(scenario, scenario_context, Measure.Time)

    if run_time >= @minimum_execution_time do
      {num_iterations, adjust_for_iterations(run_time, num_iterations)}
    else
      if fast_warning, do: printer.fast_warning()

      new_context = %ScenarioContext{
        scenario_context
        | num_iterations: num_iterations * @times_multiplier
      }

      determine_n_times(scenario, new_context, false)
    end
  end

  # `run_times` is kept separately from the `Scenario` so that for the
  # `parallel` execution case we can easily concatenate and flatten the results
  # of all processes. That's why we add them to the scenario once after
  # measuring has finished. `scenario` is still needed in general for the
  # benchmarking function, hooks etc.
  defp do_benchmark(
         _scenario,
         %ScenarioContext{
           current_time: current_time,
           end_time: end_time
         },
         _measurer,
         measurements
       )
       when current_time > end_time do
    # restore correct order - important for graphing
    Enum.reverse(measurements)
  end

  defp do_benchmark(scenario, scenario_context, measurer, measurements) do
    measurement = iteration_measurements(scenario, scenario_context, measurer)
    updated_context = %ScenarioContext{scenario_context | current_time: current_time()}

    do_benchmark(
      scenario,
      updated_context,
      measurer,
      updated_measurements(measurement, measurements)
    )
  end

  # We return `nil` if memory measurement failed so keep it empty
  defp updated_measurements(nil, measurements), do: measurements
  defp updated_measurements(measurement, measurements), do: [measurement | measurements]

  defp iteration_measurements(
         scenario,
         scenario_context = %ScenarioContext{
           num_iterations: num_iterations
         },
         measurer
       ) do
    measurement = measure_iteration(scenario, scenario_context, measurer)

    adjust_for_iterations(measurement, num_iterations)
  end

  defp adjust_for_iterations(measurement, 1), do: measurement
  defp adjust_for_iterations(measurement, num_iterations), do: measurement / num_iterations

  defp measure_iteration(
         scenario = %Scenario{function: function},
         scenario_context = %ScenarioContext{
           num_iterations: 1,
         },
         measurer
       ) do
    new_input = run_before_each(scenario, scenario_context)
    function = main_function(function, new_input)

    {measurement, return_value} = measurer.measure(function)

    run_after_each(return_value, scenario, scenario_context)
    measurement
  end

  defp measure_iteration(
         scenario,
         scenario_context = %ScenarioContext{
           num_iterations: iterations
         },
         measurer
       )
       when iterations > 1 do
    # When we have more than one iteration, then the repetition and calling
    # of hooks is already included in the function, for reference/reasoning see
    # `build_benchmarking_function/2`
    function = build_benchmarking_function(scenario, scenario_context)

    {measurement, _return_value} = measurer.measure(function)

    measurement
  end

  @no_input Benchmark.no_input()
  defp main_function(function, @no_input), do: function
  defp main_function(function, input), do: fn -> function.(input) end

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
    main = main_function(function, input)
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
          new_input = run_before_each(scenario, scenario_context)
          main = main_function(function, new_input)
          return_value = main.()
          run_after_each(return_value, scenario, scenario_context)
        end,
        iterations
      )
    end
  end

  defp run_before_each(
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

  defp run_after_each(
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
end
