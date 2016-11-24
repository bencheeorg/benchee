defmodule Benchee.Benchmark do
  @moduledoc """
  Functionality related to the actual benchmarking. Meaning running the
  given functions and recording their individual run times in a list.
  Exposes `benchmark` function.
  """

  alias Benchee.Utility.RepeatN
  alias Benchee.Conversion.Duration

  @doc """
  Adds the given function and its associated name to the benchmarking jobs to
  be run in this benchmarking suite as a tuple `{name, function}` to the list
  under the `:jobs` key.
  """
  def benchmark(suite = %{jobs: jobs}, name, function) do
    if Map.has_key?(jobs, name) do
      IO.puts "You already have a job defined with the name \"#{name}\", you can't add two jobs with the same name!"
      suite
    else
      %{suite | jobs: Map.put(jobs, name, function)}
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
  def measure(suite = %{jobs: jobs, config: config}) do
    print_configuration_information(jobs, config)
    run_times = record_runtimes(jobs, config)

    Map.put suite, :run_times, run_times
  end

  defp print_configuration_information(_, %{print: %{configuration: false}}) do
    nil
  end
  defp print_configuration_information(jobs, config) do
    print_system_information
    print_suite_information(jobs, config)
  end

  defp print_system_information do
    IO.write :erlang.system_info(:system_version)
    IO.puts "Elixir #{System.version}"
  end

  defp print_suite_information(jobs, %{parallel: parallel,
                                       time:     time,
                                       warmup:   warmup,
                                       inputs:   inputs}) do
    warmup_seconds = time_precision Duration.scale(warmup, :second)
    time_seconds   = time_precision Duration.scale(time, :second)
    job_count      = map_size jobs
    exec_time      = warmup_seconds + time_seconds
    total_time     = time_precision(job_count * inputs_count(inputs) * exec_time)

    IO.puts "Benchmark suite executing with the following configuration:"
    IO.puts "warmup: #{warmup_seconds}s"
    IO.puts "time: #{time_seconds}s"
    IO.puts "parallel: #{parallel}"
    IO.puts "inputs: #{inputs_out(inputs)}"
    IO.puts "Estimated total run time: #{total_time}s"
    IO.puts ""
  end

  defp inputs_count(nil),    do: 1 # no input specified still executes
  defp inputs_count(inputs), do: map_size(inputs)

  defp inputs_out(nil), do: "none specified"
  defp inputs_out(inputs) do
    inputs
    |> Map.keys
    |> Enum.join(", ")
  end

  @round_precision 2
  defp time_precision(float) do
    Float.round(float, @round_precision)
  end

  @no_input :__no_input
  @no_input_marker {@no_input, @no_input}

  @doc """
  Key in the result for when there were no inputs given.
  """
  def no_input, do: @no_input

  defp record_runtimes(jobs, config = %{inputs: nil}) do
    [runtimes_for_input(@no_input_marker, jobs, config)]
    |> Map.new
  end
  defp record_runtimes(jobs, config = %{inputs: inputs}) do
    inputs
    |> Enum.map(fn(input) -> runtimes_for_input(input, jobs, config) end)
    |> Map.new
  end

  defp runtimes_for_input({input_name, input}, jobs, config) do
    print_input_information(input_name)

    results = jobs
              |> Enum.map(fn(job) -> measure_job(job, input, config) end)
              |> Map.new

    {input_name, results}
  end

  defp print_input_information(@no_input) do
    # noop
  end
  defp print_input_information(input_name) do
    IO.puts "\nBenchmarking with input #{input_name}:"
  end

  defp measure_job({name, function}, input, config) do
    print_benchmarking name, config
    job_run_times = parallel_benchmark function, input, config
    {name, job_run_times}
  end

  defp print_benchmarking(_, %{print: %{benchmarking: false}}) do
    nil
  end
  defp print_benchmarking(name, _config) do
    IO.puts "Benchmarking #{name}..."
  end

  defp parallel_benchmark(function,
                          input,
                          %{parallel: parallel,
                            time:     time,
                            warmup:   warmup,
                            print:    %{fast_warning: fast_warning}}) do
    pmap 1..parallel, fn ->
      run_warmup function, input, warmup
      measure_runtimes function, input, time, fast_warning
    end
  end

  defp pmap(collection, func) do
    collection
    |> Enum.map(fn(_) -> Task.async(func) end)
    |> Enum.map(&Task.await(&1, :infinity))
    |> List.flatten
  end

  defp run_warmup(function, input, time) do
    measure_runtimes(function, input, time, false)
  end

  defp measure_runtimes(function, input, time, display_fast_warning)
  defp measure_runtimes(_function, _input, 0, _) do
    []
  end

  defp measure_runtimes(function, input, time, display_fast_warning) do
    finish_time = current_time + time
    :erlang.garbage_collect
    {n, initial_run_time} = determine_n_times(function, input, display_fast_warning)
    do_benchmark(finish_time, function, input, [initial_run_time], n)
  end

  defp current_time do
    :erlang.system_time :micro_seconds
  end

  # If a function executes way too fast measurements are too unreliable and
  # with too high variance. Therefore determine an n how often it should be
  # executed in the measurement cycle.
  @minimum_execution_time 10
  @times_multiplicator 10
  defp determine_n_times(function, input, display_fast_warning) do
    run_time = measure_call function, input
    if run_time >= @minimum_execution_time do
      {1, run_time}
    else
      if display_fast_warning, do: print_fast_warning
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

  @fast_warning """
  Warning: The function you are trying to benchmark is super fast, making measures more unreliable! See: https://github.com/PragTob/benchee/wiki/Benchee-Warnings#fast-execution-warning
  """
  defp print_fast_warning do
    IO.puts @fast_warning
  end

  defp do_benchmark(finish_time, function, input, run_times, n, now \\ 0)
  defp do_benchmark(finish_time, _, _, run_times, _n, now)
       when now > finish_time do
    run_times
  end
  defp do_benchmark(finish_time, function, input, run_times, n, _now) do
    run_time = measure_call(function, input, n)
    updated_run_times = [run_time | run_times]
    do_benchmark(finish_time, function, input,
                 updated_run_times, n, current_time())
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
