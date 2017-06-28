defmodule Benchee.Benchmark.Runner do
  @moduledoc """
  This module is the runner for a given set of benchmarks. It runs the
  benchmarks given, and returns benchmarks with the run times and memory usage
  information for output.
  """
  alias Benchee.Utility.RepeatN
  alias Benchee.Benchmark

  @no_input :__no_input
  def no_input, do: @no_input

  def run_benchmarks(benchmarks) do
    Enum.map(benchmarks, &parallel_benchmark/1)
  end

  defp parallel_benchmark(benchmark = %Benchmark{name: name,
                                                 config: config,
                                                 printer: printer}) do
    printer.benchmarking name, config
    pmap 1..config.parallel, fn ->
      run_warmup(benchmark)
      measure_runtimes(benchmark)
    end
  end

  defp pmap(collection, func) do
    collection
    |> Enum.map(fn(_) -> Task.async(func) end)
    |> Enum.map(&Task.await(&1, :infinity))
    |> List.flatten
  end

  defp run_warmup(benchmark = %Benchmark{config: config}) do
    print = Map.put(config.print, :fast_warning, false)
    config = config |> Map.put(:print, print) |> Map.put(:time, config.warmup)
    benchmark = %Benchmark{benchmark | config: config}
    measure_runtimes(benchmark)
  end

  defp measure_runtimes(%Benchmark{config: %{time: 0}}), do: []
  defp measure_runtimes(benchmark = %Benchmark{config: %{time: time}}) do
    finish_time = current_time() + time
    :erlang.garbage_collect
    {n, initial_run_time} = determine_n_times(benchmark)
    benchmark = %Benchmark{benchmark | run_times: [initial_run_time]}
    do_benchmark(benchmark, n, current_time(), finish_time)
  end

  defp current_time do
    :erlang.system_time :micro_seconds
  end

  # If a function executes way too fast measurements are too unreliable and
  # with too high variance. Therefore determine an n how often it should be
  # executed in the measurement cycle.
  @minimum_execution_time 10
  @times_multiplicator 10
  defp determine_n_times(benchmark = %Benchmark{printer: printer, config: %{print: print}}) do
    run_time = measure_call(benchmark)
    if run_time >= @minimum_execution_time do
      {1, run_time}
    else
      if print.fast_warning, do: printer.fast_warning()
      try_n_times(benchmark, @times_multiplicator)
    end
  end

  defp try_n_times(benchmark, n) do
    run_time = measure_call_n_times(benchmark, n)
    if run_time >= @minimum_execution_time do
      {n, run_time / n}
    else
      try_n_times(benchmark, n * @times_multiplicator)
    end
  end

  defp do_benchmark(benchmark, n, current_time, finish_time)
  defp do_benchmark(benchmark = %Benchmark{run_times: run_times}, _, current_time, finish_time)
    when current_time > finish_time do
    # It is important for these to be in the correct order for graphing
    ordered_run_times = Enum.reverse(run_times)
    %Benchmark{benchmark | run_times: ordered_run_times}
  end
  defp do_benchmark(benchmark = %Benchmark{run_times: run_times}, n, _, finish_time) do
    run_time = measure_call(benchmark, n)
    benchmark = %Benchmark{run_times: [run_time | run_times]}
    do_benchmark(benchmark, n, current_time(), finish_time)
  end

  defp measure_call(benchmark, n \\ 1)
  defp measure_call(%Benchmark{function: function, input: @no_input}, 1) do
    {microseconds, _return_value} = :timer.tc function
    microseconds
  end
  defp measure_call(%Benchmark{function: function, input: input}, 1) do
    {microseconds, _return_value} = :timer.tc function, [input]
    microseconds
  end
  defp measure_call(benchmark, n) do
    measure_call_n_times(benchmark, n) / n
  end

  defp measure_call_n_times(%Benchmark{function: function, input: @no_input}, n) do
    {microseconds, _return_value} = :timer.tc fn ->
      RepeatN.repeat_n(function, n)
    end

    microseconds
  end
  defp measure_call_n_times(%Benchmark{function: function, input: input}, n) do
    call_with_arg = fn ->
      function.(input)
    end
    {microseconds, _return_value} = :timer.tc fn ->
      RepeatN.repeat_n(call_with_arg, n)
    end

    microseconds
  end
end
