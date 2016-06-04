defmodule Benchee do
  @moduledoc """
  Top level module providing convenience access to needed functions as well
  as the very high level `Benchee.run` API.
  """

  @doc """
  High level interface that runs the given benchmarks and prints the results on
  the console. It is given an optional config and an array of tuples
  of names and functions to benchmark. For configuration options see the
  documentation of Benchee.init/1.

  Example:
  `Benchee.run(%{time: 3},
               [{"My Benchmark", fn -> 1 + 1 end},
                {"My other benchmrk", fn -> "1" ++ "1" end}])`
  """
  def run(config \\ %{}, jobs) do
    config
    |> Benchee.init
    |> run_benchmarks(jobs)
    |> Benchee.Statistics.statistics
    |> Benchee.Formatters.Console.format
    |> IO.puts
  end

  defp run_benchmarks(suite, jobs) do
    Enum.reduce jobs, suite, fn({name, function}, suite) ->
      benchmark(suite, name, function)
    end
  end

  @doc """
  Convenience access to `Benchee.Config.init` to initialize the configuration.

  iex> Benchee.init
  %{config: %{time: 5_000_000}, jobs: []}

  iex> Benchee.init %{time: 1}
  %{config: %{time: 1_000_000}, jobs: []}
  """
  def init(config \\ %{}) do
    Benchee.Config.init(config)
  end

  @doc """
  Runs the given benchmark for the configured time and returns a suite with
  the benchmarking results added to jobs..
  """
  def benchmark(suite, name, function) do
    Benchee.Benchmark.benchmark(suite, name, function)
  end

  @doc """
  Convenience access to Benchee.Statistics.statistics to generate statistics.

  iex> run_times = [200, 400, 400, 400, 500, 500, 700, 900]
  iex> suite = %{jobs: [{"My Job", run_times}]}
  iex> Benchee.Statistics.statistics(suite)
  [{"My Job", %{average: 500.0, std_dev: 200.0, std_dev_ratio: 0.4, ips: 2000.0}}]
  """
  def statistics(suite) do
    Benchee.Statistics.statistics(suite)
  end
end
