defmodule Benchee.Benchmark.Runner do
  @moduledoc """
  Internal module "running" a scenario, measuring all defined measurements.
  """

  # This module actually runs our benchmark scenarios, adding information about
  # run time and memory usage to each scenario.

  alias Benchee.Benchmark.BenchmarkConfig
  alias Benchee.{Benchmark, Scenario, Utility.Parallel}

  alias Benchmark.{
    Collect,
    FunctionCallOverhead,
    Hooks,
    RepeatedMeasurement,
    ScenarioContext
  }

  @no_input Benchmark.no_input()
  @zero_values [0, 0.0]

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
    case scenario_context.config.pre_check do
      true -> Enum.each(scenarios, fn scenario -> pre_check(scenario, scenario_context) end)
      false -> :ok
      :all_same -> pre_check_all_same(scenarios, scenario_context)
    end

    function_call_overhead =
      if scenario_context.config.measure_function_call_overhead do
        measure_and_report_function_call_overhead(scenario_context.printer)
      else
        0
      end

    scenario_context = %ScenarioContext{
      scenario_context
      | function_call_overhead: function_call_overhead
    }

    Enum.map(scenarios, fn scenario -> parallel_benchmark(scenario, scenario_context) end)
  end

  # This will run the given scenario exactly once, including the before and
  # after hooks, to ensure the function can execute without raising an error.
  defp pre_check(scenario, scenario_context) do
    run_once(scenario, scenario_context)
  end

  def run_once(scenario, scenario_context) do
    scenario_input = Hooks.run_before_scenario(scenario, scenario_context)
    scenario_context = %ScenarioContext{scenario_context | scenario_input: scenario_input}
    return_value = collect_return_value(scenario, scenario_context)
    _ = Hooks.run_after_scenario(scenario, scenario_context)
    return_value
  end

  defp pre_check_all_same(scenarios, scenario_context) do
    Enum.reduce(scenarios, %{}, fn %{input_name: input_name} = scenario, previous_runs ->
      return_value = pre_check(scenario, scenario_context)

      case previous_runs do
        %{^input_name => {previous_job, previous_value}} when return_value !== previous_value ->
          raise Benchee.PreCheckError,
            message: """
            all_same pre check failed#{pre_check_failed_input_message(input_name)}:
            - #{previous_job} returned #{inspect(previous_value)}
            - #{scenario.job_name} returned #{inspect(return_value)}
            """

        _ ->
          Map.put_new(previous_runs, input_name, {scenario.job_name, return_value})
      end
    end)
  end

  defp pre_check_failed_input_message(@no_input), do: ""
  defp pre_check_failed_input_message(input_name), do: " for input #{inspect(input_name)}"

  def measure_and_report_function_call_overhead(printer) do
    overhead = FunctionCallOverhead.measure()
    printer.function_call_overhead(overhead)
    overhead
  end

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
    Parallel.map(1..config.parallel, fn _ -> measure_scenario(scenario, scenario_context) end)
  end

  defp add_measurements_to_scenario(measurements, scenario) do
    run_times = Enum.flat_map(measurements, fn {run_times, _, _} -> run_times end)
    memory_usages = Enum.flat_map(measurements, fn {_, memory_usages, _} -> memory_usages end)
    reductions = Enum.flat_map(measurements, fn {_, _, reductions} -> reductions end)

    %{
      scenario
      | run_time_data: %{scenario.run_time_data | samples: run_times},
        memory_usage_data: %{scenario.memory_usage_data | samples: memory_usages},
        reductions_data: %{scenario.reductions_data | samples: reductions}
    }
  end

  @spec measure_scenario(Scenario.t(), ScenarioContext.t()) :: {[number], [number], [number]}
  defp measure_scenario(scenario, scenario_context) do
    scenario_input = Hooks.run_before_scenario(scenario, scenario_context)
    scenario_context = %ScenarioContext{scenario_context | scenario_input: scenario_input}

    _ = run_warmup(scenario, scenario_context)

    run_times =
      scenario
      |> run_runtime_benchmark(scenario_context)
      |> deduct_function_call_overhead(scenario_context.function_call_overhead)

    memory_usages = run_memory_benchmark(scenario, scenario_context)

    reductions =
      scenario
      |> run_reductions_benchmark(scenario_context)
      |> deduct_reduction_overhead()

    Hooks.run_after_scenario(scenario, scenario_context)

    {run_times, memory_usages, reductions}
  end

  defp run_warmup(
         scenario,
         scenario_context = %ScenarioContext{
           config: %BenchmarkConfig{warmup: warmup}
         }
       ) do
    measure_runtimes(scenario, scenario_context, warmup, false)
  end

  defp run_runtime_benchmark(
         scenario,
         scenario_context = %ScenarioContext{
           config: %{
             time: run_time,
             print: %{fast_warning: fast_warning}
           }
         }
       ) do
    measure_runtimes(scenario, scenario_context, run_time, fast_warning)
  end

  defp deduct_function_call_overhead(run_times, 0) do
    run_times
  end

  defp deduct_function_call_overhead(run_times, overhead) do
    Enum.map(run_times, fn time ->
      max(time - overhead, 0)
    end)
  end

  defp deduct_reduction_overhead([]), do: []

  defp deduct_reduction_overhead(reductions) do
    me = self()
    ref = make_ref()

    spawn(fn ->
      {offset, _} = Collect.Reductions.collect(fn -> nil end)
      send(me, {ref, offset})
    end)

    offset =
      receive do
        {^ref, offset} -> offset
      end

    Enum.map(reductions, &(&1 - offset))
  end

  defp run_reductions_benchmark(_, %ScenarioContext{config: %{reduction_time: time}})
       when time in @zero_values do
    []
  end

  defp run_reductions_benchmark(
         scenario,
         scenario_context = %ScenarioContext{
           config: %{
             reduction_time: reduction_time
           }
         }
       ) do
    end_time = current_time() + reduction_time

    new_context = %ScenarioContext{
      scenario_context
      | current_time: current_time(),
        end_time: end_time
    }

    do_benchmark(scenario, new_context, Collect.Reductions, [])
  end

  defp run_memory_benchmark(_, %ScenarioContext{config: %{memory_time: time}})
       when time in @zero_values do
    []
  end

  defp run_memory_benchmark(
         scenario,
         scenario_context = %ScenarioContext{
           config: %{
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

    do_benchmark(scenario, new_context, Collect.Memory, [])
  end

  @spec measure_runtimes(Scenario.t(), ScenarioContext.t(), number, boolean) :: [number]
  defp measure_runtimes(scenario, context, run_time, fast_warning)
  defp measure_runtimes(_, _, time, _) when time in @zero_values, do: []

  defp measure_runtimes(scenario, scenario_context, run_time, fast_warning) do
    end_time = current_time() + run_time
    :erlang.garbage_collect()

    {num_iterations, initial_run_time} =
      RepeatedMeasurement.determine_n_times(scenario, scenario_context, fast_warning)

    new_context = %ScenarioContext{
      scenario_context
      | current_time: current_time(),
        end_time: end_time,
        num_iterations: num_iterations,
        # we have the initial run time
        sample_size: 1
    }

    do_benchmark(scenario, new_context, Collect.Time, [initial_run_time])
  end

  defp current_time, do: :erlang.system_time(:nano_seconds)

  # `run_times` is kept separately from the `Scenario` so that for the
  # `parallel` execution case we can easily concatenate and flatten the results
  # of all processes. That's why we add them to the scenario once after
  # measuring has finished. `scenario` is still needed in general for the
  # benchmarking function, hooks etc.
  defp do_benchmark(
         _scenario,
         %ScenarioContext{
           current_time: current_time,
           end_time: end_time,
           sample_size: sample_size,
           config: %BenchmarkConfig{
             max_sample_size: max_sample_size
           }
         },
         _collector,
         measurements
       )
       when (current_time > end_time or
               (not is_nil(max_sample_size) and sample_size >= max_sample_size)) and
              measurements != [] do
    # restore correct order - important for graphing
    Enum.reverse(measurements)
  end

  defp do_benchmark(scenario, scenario_context, collector, measurements) do
    measurement = collect(scenario, scenario_context, collector)

    updated_context = %ScenarioContext{
      scenario_context
      | current_time: current_time(),
        sample_size: scenario_context.sample_size + 1
    }

    do_benchmark(
      scenario,
      updated_context,
      collector,
      updated_measurements(measurement, measurements)
    )
  end

  # We return `nil` if memory measurement failed so keep it empty
  @spec updated_measurements(number | nil, [number]) :: [number]
  defp updated_measurements(nil, measurements), do: measurements
  defp updated_measurements(measurement, measurements), do: [measurement | measurements]

  # Support functionality that just runs once via `run_once` and does not care about measurements.
  # At the time of this writing that's pre checks and profilers.
  defp collect_return_value(scenario, scenario_context) do
    new_input = Hooks.run_before_each(scenario, scenario_context)
    function = main_function(scenario.function, new_input)

    return_value = function.()

    Hooks.run_after_each(return_value, scenario, scenario_context)
    return_value
  end

  @doc """
  Takes one measure with the given collector.

  Correctly dispatches based on the number of iterations to perform.
  """
  def collect(
        scenario = %Scenario{function: function},
        scenario_context = %ScenarioContext{
          num_iterations: 1
        },
        collector
      ) do
    new_input = Hooks.run_before_each(scenario, scenario_context)
    function = main_function(function, new_input)

    {measurement, return_value} = invoke_collector(collector, function)

    Hooks.run_after_each(return_value, scenario, scenario_context)
    measurement
  end

  def collect(
        scenario,
        scenario_context = %ScenarioContext{
          num_iterations: iterations
        },
        collector
      )
      when iterations > 1 do
    RepeatedMeasurement.collect(scenario, scenario_context, collector)
  end

  def main_function(function, @no_input), do: function
  def main_function(function, input), do: fn -> function.(input) end

  defp invoke_collector({collector, collector_opts}, function),
    do: collector.collect(function, collector_opts)

  defp invoke_collector(collector, function), do: collector.collect(function)
end
