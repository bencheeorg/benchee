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
  documentation of `Benchee.Config.init/1`.

  ## Examples

      Benchee.run(%{time: 3},
                  %{"My Benchmark" => fn -> 1 + 1 end,
                    "My other benchmrk" => fn -> "1" ++ "1" end})
      # Prints a summary of the benchmark to the console

  """
  def run(config \\ %{}, jobs)
  def run(config, jobs) when is_list(jobs) do
    map_jobs = Enum.into jobs, %{}
    run(config, map_jobs)
  end
  def run(config, jobs) do
    config
    |> Benchee.init
    |> Map.put(:jobs, jobs)
    |> Benchee.measure
    |> Statistics.statistics
    |> Formatters.Console.format
    |> IO.puts
  end

  @doc """
  Convenience access to `Benchee.Config.init/1` to initialize the configuration.

  Possible options:

    * time     - total run time in seconds of a single benchmark (determines
    how often it is executed). Defaults to 5.
    * warmup   - the time in seconds for which the benchmarking function should
    be run without gathering results. Defaults to 2.
    * parallel - each job will be executed in `parallel` number processes. Gives
    you more data in the same time, but also puts a load on the system
    interfering with benchmark results. Defaults to 1.
  """
  def init(config \\ %{}) do
    Config.init(config)
  end

  @doc """
  Convenience access to `Benchee.Benchmark.benchmark/3` to define the benchmarks
  to run in this benchmarking suite.`
  """
  def benchmark(suite, name, function) do
    Benchmark.benchmark(suite, name, function)
  end


  @doc """
  Convenience access to `Benchee.Benchmark.measure/1` to run the defined
  benchmarks and measure their run time.
  """
  def measure(suite) do
    Benchmark.measure(suite)
  end

  @doc """
  Convenience access to `Benchee.Statistics.statistics/1` to generate
  statistics.

  """
  def statistics(suite) do
    Statistics.statistics(suite)
  end
end
