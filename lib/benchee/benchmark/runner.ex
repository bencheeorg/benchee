defmodule Benchee.Benchmark.Runner do
  @moduledoc """
  This module actually runs our benchmark scenarios, adding information about
  run time and memory usage to each scenario.
  """

  alias Benchee.Benchmark
  alias Benchee.Benchmark.{Scenario, ScenarioContext}
  alias Benchee.Utility.RepeatN
  alias Benchee.Configuration

  @doc """
  Executes the benchmarks defined before by first running the defined functions
  for `warmup` time without gathering results and them running them for `time`
  gathering their run times.

  This means the total run time of a single benchmarking job is warmup + time.

  Warmup is usually important for run times with JIT but it seems to have some
  effect on the BEAM as well.

  There will be `parallel` processes spawned executing the benchmark job in
  parallel.
  """
  @spec run_scenarios([Scenario.t], ScenarioContext.t) :: [Scenario.t]
  def run_scenarios(scenarios, scenario_context) do
    Enum.flat_map(scenarios, fn(scenario) ->
      parallel_benchmark(scenario, scenario_context)
    end)
  end

  defp parallel_benchmark(scenario = %Scenario{job_name: job_name, input_name: input_name},
                          scenario_context = %ScenarioContext{printer: printer, config: config}) do
    printer.input_information(input_name, config)
    printer.benchmarking(job_name, config)
    pmap 1..config.parallel, fn ->
      run_warmup(scenario, scenario_context)
      run_benchmark(scenario, scenario_context)
    end
  end

  def run_warmup(scenario, scenario_context = %ScenarioContext{
                   config: %Configuration{warmup: warmup}
                 }) do
    warmup_context = %ScenarioContext{scenario_context | show_fast_warning: false,
                                                         run_time: warmup}
    measure_runtimes(scenario, warmup_context)
  end

  def run_benchmark(scenario, scenario_context = %ScenarioContext{
                      config: %Configuration{time: run_time, print: %{fast_warning: fast_warning}}
                    }) do
    measurement_context =
      %ScenarioContext{scenario_context | show_fast_warning: fast_warning,
                                          run_time: run_time}
    measure_runtimes(scenario, measurement_context)
  end

  defp pmap(collection, func) do
    collection
    |> Enum.map(fn(_) -> Task.async(func) end)
    |> Enum.map(&Task.await(&1, :infinity))
    |> List.flatten
  end

  defp measure_runtimes(scenario, %ScenarioContext{run_time: 0}), do: scenario
  defp measure_runtimes(scenario, scenario_context = %ScenarioContext{run_time: run_time}) do
    end_time = current_time() + run_time
    :erlang.garbage_collect
    {num_iterations, initial_run_time} =
      determine_n_times(scenario, scenario_context)
    updated_scenario = %Scenario{scenario | run_times: [initial_run_time]}
    new_context =
      %ScenarioContext{scenario_context | current_time: current_time(),
                                          end_time: end_time,
                                          num_iterations: num_iterations}
    do_benchmark(updated_scenario, new_context)
  end

  defp current_time do
    :erlang.system_time :micro_seconds
  end

  # If a function executes way too fast measurements are too unreliable and
  # with too high variance. Therefore determine an n how often it should be
  # executed in the measurement cycle.
  @minimum_execution_time 10
  @times_multiplicator 10
  defp determine_n_times(scenario, scenario_context = %ScenarioContext{
                           show_fast_warning: fast_warning, printer: printer
                         }) do
    run_time = measure_call(scenario, scenario_context)
    if run_time >= @minimum_execution_time do
      {1, run_time}
    else
      if fast_warning, do: printer.fast_warning()
      new_context =
        %ScenarioContext{scenario_context | num_iterations: @times_multiplicator}
      try_n_times(scenario, new_context)
    end
  end

  defp try_n_times(scenario, scenario_context = %ScenarioContext{
                     num_iterations: num_iterations
                   }) do
    run_time = measure_call_n_times(scenario, scenario_context)
    if run_time >= @minimum_execution_time do
      {num_iterations, run_time / num_iterations}
    else
      new_context = %ScenarioContext{
        scenario_context | num_iterations: num_iterations * @times_multiplicator
      }
      try_n_times(scenario, new_context)
    end
  end

  defp do_benchmark(scenario = %Scenario{run_times: run_times}, %ScenarioContext{
                      current_time: current_time, end_time: end_time
                    }) when current_time > end_time do
    # restore correct order - important for graphing
    %Scenario{scenario | run_times: Enum.reverse(run_times)}
  end
  defp do_benchmark(scenario = %Scenario{run_times: run_times}, scenario_context) do
    run_time = measure_call(scenario, scenario_context)
    updated_scenario = %Scenario{scenario | run_times: [run_time | run_times]}
    updated_context = %ScenarioContext{scenario_context | current_time: current_time()}
    do_benchmark(updated_scenario, updated_context)
  end

  defp measure_call(scenario, scenario_context = %ScenarioContext{
                      num_iterations: num_iterations
                    }) do
    measure_call_n_times(scenario, scenario_context) / num_iterations
  end

  @no_input Benchmark.no_input()
  defp measure_call_n_times(%Scenario{function: function, input: @no_input},
                            %ScenarioContext{num_iterations: num_iterations}) do
    {microseconds, _return_value} = :timer.tc fn ->
      RepeatN.repeat_n(function, num_iterations)
    end

    microseconds
  end
  defp measure_call_n_times(%Scenario{function: function, input: input},
                            %ScenarioContext{num_iterations: num_iterations}) do
    fun_with_input = fn -> function.(input) end
    {microseconds, _return_value} = :timer.tc fn ->
      RepeatN.repeat_n(fun_with_input, num_iterations)
    end

    microseconds
  end
end
