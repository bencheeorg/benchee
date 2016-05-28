defmodule Benchee.Benchmark do
  @doc """
  Runs the given benchmark for the configured time and returns a suite with
  the benchmarking results added to jobs..
  """
  def benchmark(suite = %{config: %{time: time}}, name, function) do
    IO.puts "Benchmarking #{name}..."
    run_times = do_benchmark(time, function)
    job = {name, run_times}
    {_, suite} = Map.get_and_update! suite, :jobs, fn(jobs) ->
      {jobs, [job | jobs]}
    end
    suite
  end

  defp do_benchmark(time, function, run_times \\ [], time_taken \\ 0)

  defp do_benchmark(time, _, run_times, time_taken) when time_taken > time do
    run_times
  end

  defp do_benchmark(time, function, run_times, time_taken) do
    run_time = measure_call(function)
    do_benchmark(time, function, [run_time | run_times], time_taken + run_time)
  end

  defp measure_call(function) do
    {microseconds, _return_value} = :timer.tc function
    microseconds
  end
end
