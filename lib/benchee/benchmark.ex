defmodule Benchee.Benchmark do
  @moduledoc """
  Functionality related to the actual benchmarking. Meaning running the
  given functions and recording their individual run times in a list.
  Exposes `benchmark` function.
  """

  alias Benchee.RepeatN

  @doc """
  Adds the given function and its associated name to the benchmarking jobs to
  be run in this benchmarking suite.

  ## Examples

  iex> fun = fn -> 100 * 100 end
  iex> Benchee.Benchmark.benchmark(%{jobs: []}, "100 square", fun)
  %{jobs: [{"100 square", fun}]}
  """
  def benchmark(suite = %{jobs: jobs}, name, function) do
    %{suite | jobs: [{name, function} | jobs]}
  end


  @doc """
  Executes the benchmarks defined before by first running the defined functions
  for `warmup` time without gathering results and them running them for `time`
  gathering their run times.

  Warmup is usually important for run times with JIT but it seems to have some
  effect on the BEAM as well.
  """
  def measure(suite = %{jobs: jobs, config: %{time: time, warmup: warmup}}) do
    run_times = Enum.map jobs, fn({name, function}) ->
                  run_warmup name, function, warmup
                  job_run_times = measure_job name, function, time
                  {name, job_run_times}
                end
    Map.put suite, :run_times, run_times
  end

  defp run_warmup(name, function, time) do
    IO.puts "Running warmup for #{name}..."
    measure_runtimes(function, time)
  end

  defp measure_job(name, function, time) do
    IO.puts "Benchmarking #{name}..."
    measure_runtimes(function, time)
  end

  defp measure_runtimes(function, time) do
    finish_time = current_time + time
    :erlang.garbage_collect
    {n, initial_run_time} = determine_n_times(function)
    do_benchmark(finish_time, function, [initial_run_time], n)
  end

  defp current_time do
    :erlang.system_time :micro_seconds
  end

  # testing has shown that sometimes the first call is significantly slower
  # than the second (like 2 vs 800) so prewarm one time.
  defp prewarm(function, n \\ 1) do
    measure_call(function, n)
  end

  # If a function executes way too fast measurements are too unreliable and
  # with too high variance. Therefore determine an n how often it should be
  # executed in the measurement cycle.
  @minimum_execution_time 10
  @times_multiplicator 10
  defp determine_n_times(function) do
    prewarm function
    run_time = measure_call function
    if run_time >= @minimum_execution_time do
      {1, run_time}
    else
      try_n_times(function, @times_multiplicator)
    end
  end

  defp try_n_times(function, n) do
    prewarm function, n
    run_time = measure_call_n_times function, n
    if run_time >= @minimum_execution_time do
      repeat_notice
      {n, run_time / n}
    else
      try_n_times(function, n * @times_multiplicator)
    end
  end

  @repeat_notice """
  Warning: The function you are trying to benchmark is super fast, making time measures unreliable!
  Benchee won't measure individual runs but rather run it a couple of times and report the average back. Measures will still be correct, but the overhead of running it n times goes into the measurement. Also statistical results aren't as good, as they are based on averages now. If possible, increase the input size so that an individual run takes more than #{@minimum_execution_time}μs
  """
  defp repeat_notice do
    IO.puts @repeat_notice
  end

  defp do_benchmark(finish_time, function, run_times, n, now \\ 0)
  defp do_benchmark(finish_time, _, run_times, _n, now) when now > finish_time do
    run_times
  end
  defp do_benchmark(finish_time, function, run_times, n, _now) do
    run_time = measure_call(function, n)
    do_benchmark(finish_time, function, [run_time | run_times], n, current_time())
  end

  defp measure_call(function, n \\ 1)
  defp measure_call(function, 1) do
    {microseconds, _return_value} = :timer.tc function
    microseconds
  end
  defp measure_call(function, n) do
    measure_call_n_times(function, n) / n
  end

  defp measure_call_n_times(function, n) do
    {microseconds, _return_value} = :timer.tc fn ->
      RepeatN.repeat_n(function, n)
    end

    microseconds
  end
end
