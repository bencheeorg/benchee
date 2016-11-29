defmodule Benchee do
  @moduledoc """
  Top level module providing convenience access to needed functions as well
  as the very high level `Benchee.run` API.
  """

  alias Benchee.{Statistics, Config, Benchmark}

  @doc """
  Run benchmark jobs defined by a map and optionally provide configuration
  options.

  Runs the given benchmarks and prints the results on the console.

  * jobs - a map from descriptive benchmark job name to a function to be
  executed and benchmarked
  * config - configuration options to alter what Benchee does, see
  `Benchee.Config.init/1` for documentation of the available options.

  ## Examples

      Benchee.run(%{"My Benchmark" => fn -> 1 + 1 end,
                    "My other benchmrk" => fn -> "1" ++ "1" end}, time: 3)
      # Prints a summary of the benchmark to the console

  """
  def run(jobs, config \\ [])
  def run(jobs, config) when is_list(config) do
    do_run(jobs, config)
  end
  def run(config, jobs) when is_map(jobs) do
    # pre 0.6.0 way of passing in the config first and as a map
    do_run(jobs, config)
  end

  defp do_run(jobs, config) do
    suite = run_benchmarks jobs, config
    output_results suite
    suite
  end

  defp run_benchmarks(jobs, config) do
    config
    |> Benchee.init
    |> Benchee.System.system
    |> Map.put(:jobs, jobs)
    |> Benchee.measure
    |> Statistics.statistics
  end

  defp output_results(suite = %{config: %{formatters: formatters}}) do
    Enum.each formatters, fn(output_function) ->
      output_function.(suite)
    end
  end

  @doc """
  Convenience access to `Benchee.Config.init/1` to initialize the configuration.
  """
  def init(config \\ %{}) do
    Config.init(config)
  end

  @doc """
  Convenience access to `Benchee.Benchmark.benchmark/3` to define the benchmarks
  to run in this benchmarking suite.
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
