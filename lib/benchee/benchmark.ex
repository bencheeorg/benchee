defmodule Benchee.Benchmark do
  @doc """
  Runs the given benchmark for the configured time and returns a suite with
  the benchmarking results added to jobs..
  """
  def benchmark(suite = %{config: %{time: time}}, name, function) do
    IO.puts "Benchmarking #{name}..."
    finish_time = current_time + time
    run_times = do_benchmark(finish_time, function)
    job = {name, run_times}
    {_, suite} = Map.get_and_update! suite, :jobs, fn(jobs) ->
      {jobs, [job | jobs]}
    end
    suite
  end

  defp current_time do
    :erlang.system_time :micro_seconds
  end

  defp do_benchmark(finish_time, function, run_times \\ [], now \\ 0)

  defp do_benchmark(finish_time, _, run_times, now) when now > finish_time do
    run_times
  end

  defp do_benchmark(finish_time, function, run_times, _now) do
    run_time = measure_call(function)
    do_benchmark(finish_time, function, [run_time | run_times], current_time())
  end

  defp measure_call(function) do
    {microseconds, _return_value} = :timer.tc function
    microseconds
  end
end
