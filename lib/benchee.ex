defmodule Benchee do
  @moduledoc """
  Top level module providing convenience access to needed functions as well
  as the very high level `Benchee.run` API.
  """

  alias Benchee.{Statistics, Formatters, Config, Benchmark}

  @doc """
  High level interface that runs the given benchmarks and prints the results on
  the console. It is given an optional config and an array of tuples
  of names and functions to benchmark. For configuration options see the
  documentation of Benchee.init/1.

  ## Examples

      Benchee.run(%{time: 3},
                   [{"My Benchmark", fn -> 1 + 1 end},
                    {"My other benchmrk", fn -> "1" ++ "1" end}])
      # Prints a summary of the benchmark to the console

  """
  def run(config \\ %{}, jobs) do
    config
    |> Benchee.init
    |> run_benchmarks(jobs)
    |> Statistics.statistics
    |> Formatters.Console.format
    |> IO.puts
  end

  defp run_benchmarks(suite, jobs) do
    Enum.reduce jobs, suite, fn({name, function}, suite) ->
      benchmark(suite, name, function)
    end
  end

  @doc """
  Convenience access to `Benchee.Config.init/1` to initialize the configuration.

  ## Examples

      iex> Benchee.init
      %{config: %{time: 5_000_000}, jobs: []}

      iex> Benchee.init %{time: 1}
      %{config: %{time: 1_000_000}, jobs: []}

  """
  def init(config \\ %{}) do
    Config.init(config)
  end

  @doc """
  Convenience access to `Benchee.Benchmark.benchmark/3` to runs the given
  benchmark for the configured time and returns a suite with the benchmarking
  results added.
  """
  def benchmark(suite, name, function) do
    Benchmark.benchmark(suite, name, function)
  end

  @doc """
  Convenience access to `Benchee.Statistics.statistics/1` to generate
  statistics.

  ## Examples

      iex> run_times = [200, 400, 400, 400, 500, 500, 700, 900]
      iex> suite = %{jobs: [{"My Job", run_times}]}
      iex> Benchee.Statistics.statistics(suite)
      [{"My Job",
        %{average:       500.0,
          std_dev:       200.0,
          std_dev_ratio: 0.4,
          ips:           2000.0,
          median:        450.0}}]

  """
  def statistics(suite) do
    Statistics.statistics(suite)
  end
end
