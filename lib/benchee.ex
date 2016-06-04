defmodule Benchee do

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
    Benchee.init(config)
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
  Returns the initial benchmark configuration for Benhee, composed of defauls
  and an optional custom confiuration.
  Configuration times are given in seconds, but are converted to microseconds.

  Possible options:
  * time - total run time of a single benchmark (determines how often it is
           executed)

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
end
