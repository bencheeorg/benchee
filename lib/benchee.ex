defmodule Benchee do
  @moduledoc """
  Top level module providing convenience access to needed functions as well
  as the very high level `Benchee.run` API.
  """

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
    |> Benchee.system
    |> Map.put(:jobs, jobs)
    |> Benchee.measure
    |> Benchee.statistics
  end

  defp output_results(suite = %{config: %{formatters: formatters}}) do
    Enum.each formatters, fn(output_function) ->
      output_function.(suite)
    end
  end

  defdelegate init(),                                    to: Benchee.Config
  defdelegate init(config),                              to: Benchee.Config
  defdelegate system(suite),                             to: Benchee.System
  defdelegate measure(suite),                            to: Benchee.Benchmark
  defdelegate measure(suite, printer),                   to: Benchee.Benchmark
  defdelegate benchmark(suite, name, function),          to: Benchee.Benchmark
  defdelegate benchmark(suite, name, function, printer), to: Benchee.Benchmark
  defdelegate statistics(suite),                         to: Benchee.Statistics
end
