defmodule Benchee do
  @default_config %{time: 5}

  alias Benchee.{Statistics, Time}

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

  @seconds_to_microseconds 1_000_000
  defp convert_time_to_micro_s(config) do
    {_, config} = Map.get_and_update! config, :time, fn(seconds) ->
      {seconds, Time.seconds_to_microseconds(seconds)}
    end
    config
  end

  @doc """
  Runs the given benchmark for the configured time and returns a suite with
  the benchmark results added.
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

  defp do_benchmark(time, function, results \\ [], total_run_time \\ 0)

  defp do_benchmark(time, _, results, time_taken) when time_taken > time do
    results
  end

  defp do_benchmark(time, function, results, total_run_time) do
    run_time = measure_call(function)
    do_benchmark(time, function, [run_time | results], total_run_time + run_time)
  end

  defp measure_call(function) do
    {microseconds, _return_value} = :timer.tc function
    microseconds
  end

  @doc """
  Creates a report of the benchmark suite run.
  """
  def report(%{jobs: jobs}) do

    Enum.map jobs, fn(%{name: name, run_times: times}) ->
      %{average:      average,
        ips:          ips,
        std_dev_ratio: std_dev_ratio} = Statistics.statistics(times)
      "#{name} #{ips} #{average}μs (±#{std_dev_ratio * 100.0}%)\n"
    end
  end


end
