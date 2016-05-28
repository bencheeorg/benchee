defmodule Benchee do
  @default_config %{time: 5}

  alias Benchee.{Time}

  @doc """
  Returns the initial benchmark suite data structure for Benshee.
  Given an optional map of configuration options, converts seconds in there
  to microseconds.

  iex> Benchee.init
  %{config: %{time: 5_000_000}, jobs: []}

  iex> Benchee.init %{time: 1}
  %{config: %{time: 1_000_000}, jobs: []}
  """
  def init(config \\ %{}) do
    config = convert_time_to_micro_s(Map.merge(@default_config, config))
    %{config: config, jobs: []}
  end

  defp convert_time_to_micro_s(config) do
    {_, config} = Map.get_and_update! config, :time, fn(seconds) ->
      {seconds, Time.seconds_to_microseconds(seconds)}
    end
    config
  end

  @doc """
  Runs the given benchmark for the configured time and returns a suite with
  the benchmark run_times added.
  """
  def benchmark(suite = %{config: %{time: time}}, name, function) do
    IO.puts "Benchmarking #{name}..."
    run_times = do_benchmark(time, function)
    job = %{name: name, run_times: run_times}
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
