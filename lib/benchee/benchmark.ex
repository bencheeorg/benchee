defmodule Benchee.Benchmark do
  @moduledoc """
  Functionality related to the actual benchmarking. Meaning running the
  given functions and recording their individual run times in a list.
  Exposes `benchmark` function.
  """

  alias Benchee.Utility.RepeatN
  alias Benchee.Output.BenchmarkPrinter, as: Printer
  alias Benchee.Suite

  @type name :: String.t

  @doc """
  Adds the given function and its associated name to the benchmarking jobs to
  be run in this benchmarking suite as a tuple `{name, function}` to the list
  under the `:jobs` key.
  """
  @spec benchmark(Suite.t, name, fun, module) :: Suite.t
  def benchmark(suite = %Suite{jobs: jobs}, name, function, printer \\ Printer) do
    normalized_name = to_string(name)
    if Map.has_key?(jobs, normalized_name) do
      printer.duplicate_benchmark_warning normalized_name
      suite
    else
      %Suite{suite | jobs: Map.put(jobs, normalized_name, function)}
    end
  end


  @doc """
  Executes the benchmarks defined before by first running the defined functions
  for `warmup` time without gathering results and them running them for `time`
  gathering their run times.

  This means the total run time of a single benchmarking job is warmup + time.

  Warmup is usually important for run times with JIT but it seems to have some
  effect on the BEAM as well.

  There will be `parallel` processes spawned exeuting the benchmark job in
  parallel.
  """
  @spec measure(Suite.t, module) :: Suite.t
  def measure(suite = %Suite{jobs: jobs, configuration: config}, printer \\ Printer) do
    printer.configuration_information(suite)
    results = record_results(jobs, config, printer)
    run_times = parse_results(results, fn({key, {run_times, _}}) ->
      {key, run_times}
    end)
    memory_usages = parse_results(results, fn({key, {_, memory_usages}}) ->
      {key, memory_usages}
    end)

    %Suite{suite | run_times: run_times, memory_usages: memory_usages}
  end

  defp parse_results(results, func) do
    results
      |> Enum.map(fn({input, map}) ->
        {input, map |> Enum.map(func) |> Map.new}
      end)
      |> Map.new
  end

  @no_input :__no_input
  @no_input_marker {@no_input, @no_input}

  @doc """
  Key in the result for when there were no inputs given.
  """
  def no_input, do: @no_input

  defp record_results(jobs, config = %{inputs: nil}, printer) do
    [runtimes_for_input(@no_input_marker, jobs, config, printer)]
    |> Map.new
  end
  defp record_results(jobs, config = %{inputs: inputs}, printer) do
    inputs
    |> Enum.map(fn(input) ->
         runtimes_for_input(input, jobs, config, printer)
       end)
    |> Map.new
  end

  defp runtimes_for_input({input_name, input}, jobs, config, printer) do
    printer.input_information(input_name, config)

    results =
      jobs
      |> Enum.map(fn(job) -> measure_job(job, input, config, printer) end)
      |> Map.new

    {input_name, results}
  end

  defp measure_job({name, function}, input, config, printer) do
    printer.benchmarking name, config
    results = parallel_benchmark function, input, config, printer
    job_run_times = results |> Enum.map(fn({run_times, _memory_usages}) -> run_times end) |> List.flatten
    memory_usages = results |> Enum.map(fn({_run_times, memory_usages}) -> memory_usages end) |> List.flatten
    {name, {job_run_times, memory_usages}}
  end

  defp parallel_benchmark(function,
                          input,
                          %{parallel: parallel,
                            time:     time,
                            warmup:   warmup,
                            print:    %{fast_warning: fast_warning}},
                          printer) do
    pmap 1..parallel, fn ->
      _ = run_warmup function, input, warmup, printer
      measure_runtimes function, input, time, fast_warning, printer
    end
  end

  defp pmap(collection, func) do
    collection
    |> Enum.map(fn(_) -> Task.async(func) end)
    |> Enum.map(&Task.await(&1, :infinity))
    |> List.flatten
  end

  defp run_warmup(function, input, time, printer) do
    measure_runtimes(function, input, time, false, printer)
  end

  defp measure_runtimes(function, input, time, display_fast_warning, printer)
  defp measure_runtimes(_function, _input, 0, _, _) do
    []
  end
  defp measure_runtimes(function, input, time, display_fast_warning, printer) do
    finish_time = current_time() + time
    :erlang.garbage_collect()
    {n, initial_run_time} =
      determine_n_times(function, input, display_fast_warning, printer)
    do_benchmark(finish_time, function, input, [initial_run_time], [], n, current_time())
  end

  defp current_time do
    :erlang.system_time :micro_seconds
  end

  # If a function executes way too fast measurements are too unreliable and
  # with too high variance. Therefore determine an n how often it should be
  # executed in the measurement cycle.
  @minimum_execution_time 10
  @times_multiplicator 10
  defp determine_n_times(function, input, display_fast_warning, printer) do
    run_time = measure_call function, input
    if run_time >= @minimum_execution_time do
      {1, run_time}
    else
      if display_fast_warning, do: printer.fast_warning()
      try_n_times(function, input, @times_multiplicator)
    end
  end

  defp try_n_times(function, input, n) do
    run_time = measure_call_n_times function, input, n
    if run_time >= @minimum_execution_time do
      {n, run_time / n}
    else
      try_n_times(function, input, n * @times_multiplicator)
    end
  end

  defp do_benchmark(finish_time, function, input, run_times, memory_usages, n, now)
  defp do_benchmark(finish_time, _, _, run_times, memory_usages, _n, now)
       when now > finish_time do
    {Enum.reverse(run_times), memory_usages}
  end
  defp do_benchmark(finish_time, function, input, run_times, memory_usages, n, _now) do
    :erlang.garbage_collect()
    before_run = :erlang.memory(:total)
    run_time = measure_call(function, input, n)
    after_run = :erlang.memory(:total)
    updated_run_times = [run_time | run_times]
    updated_memory_usages = [after_run - before_run | memory_usages]
    do_benchmark(finish_time, function, input,
                 updated_run_times, updated_memory_usages, n, current_time())
  end

  defp measure_call(function, input, n \\ 1)
  defp measure_call(function, @no_input, 1) do
    {microseconds, _return_value} = :timer.tc function
    microseconds
  end
  defp measure_call(function, input, 1) do
    {microseconds, _return_value} = :timer.tc function, [input]
    microseconds
  end
  defp measure_call(function, input, n) do
    measure_call_n_times(function, input, n) / n
  end

  defp measure_call_n_times(function, @no_input, n) do
    {microseconds, _return_value} = :timer.tc fn ->
      RepeatN.repeat_n(function, n)
    end

    microseconds
  end
  defp measure_call_n_times(function, input, n) do
    call_with_arg = fn ->
      function.(input)
    end
    {microseconds, _return_value} = :timer.tc fn ->
      RepeatN.repeat_n(call_with_arg, n)
    end

    microseconds
  end
end
