defmodule Benchee.Benchmark do
  @moduledoc """
  Functionality related to the actual benchmarking. Meaning running the
  given functions and recording their individual run times in a list.
  Exposes `benchmark` function.
  """

  alias Benchee.RepeatN

  @doc """
  Runs the given benchmark for the time configured in the benchmark suite and
  returns a the benchmarking suite results added to the  `:jobs` key.
  Runs garbage collection before running the given function and measuring
  the times so that previous benchmarks don't interfere with its result.
  """
  def benchmark(suite = %{config: %{time: time}}, name, function) do
    IO.puts "Benchmarking #{name}..."
    finish_time = current_time + time
    :erlang.garbage_collect
    {n, initial_run_time} = determine_n_times(function)
    run_times = do_benchmark(finish_time, function, [initial_run_time], n)
    job = {name, run_times}
    {_, suite} = Map.get_and_update! suite, :jobs, fn(jobs) ->
      {jobs, [job | jobs]}
    end
    suite
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
  @minimum_execution_time 20
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
  The function you are trying to benchmark is super fast, making time measures unreliable!
  Benchee won't measure individual runs but rather run it a couple of times and report the average back. Measures will still be correct, but there's less trust in the statistical results. If possible, increase the input size so that an individual run takes more than #{@minimum_execution_time}μs
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
