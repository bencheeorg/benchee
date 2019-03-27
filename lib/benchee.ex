# Idea from this:
# credo:disable-for-next-line
# https://github.com/PragTob/benchee/commit/b3ddbc132e641cdf1eec0928b322ced1dab8553f#commitcomment-23381474

elixir_doc = """
Top level module providing convenience access to needed functions as well
as the very high level `Benchee.run` API.

Intended Elixir interface.
"""

erlang_doc = """
High-Level interface for more convenient usage from Erlang. Same as `Benchee`.
"""

for {module, moduledoc} <- [{Benchee, elixir_doc}, {:benchee, erlang_doc}] do
  defmodule module do
    @moduledoc moduledoc

    alias Benchee.Formatter

    @doc """
    Run benchmark jobs defined by a map and optionally provide configuration
    options.

    Runs the given benchmarks and prints the results on the console.

    * jobs - a map from descriptive benchmark job name to a function to be
    executed and benchmarked
    * configuration - configuration options to alter what Benchee does, see
    `Benchee.Configuration.init/1` for documentation of the available options.

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
      IO.puts("""
      Passing configuration as the first argument to Benchee.run/2 is deprecated.
      Please see the documentation for Benchee.run/2 for updated usage instructions.
      """)

      # pre 0.6.0 way of passing in the config first and as a map
      do_run(jobs, config)
    end

    defp do_run(jobs, config) do
      config
      |> Benchee.init()
      |> Benchee.system()
      |> add_benchmarking_jobs(jobs)
      |> Benchee.collect()
      |> Benchee.statistics()
      |> Benchee.load()
      |> Benchee.relative_statistics()
      |> Formatter.output()
    end

    defp add_benchmarking_jobs(suite, jobs) do
      Enum.reduce(jobs, suite, fn {key, function}, suite_acc ->
        Benchee.benchmark(suite_acc, key, function)
      end)
    end

    @doc false
    def measure(suite) do
      IO.puts("""
      Benchee.measure/1 is deprecated, please use Benchee.collect/1.
      """)

      Benchee.Benchmark.collect(suite)
    end

    @doc """
    See `Benchee.Configuration.init/1`
    """
    defdelegate init(), to: Benchee.Configuration

    @doc """
    See `Benchee.Configuration.init/1`
    """
    defdelegate init(config), to: Benchee.Configuration

    @doc """
    See `Benchee.System.system/1`
    """
    defdelegate system(suite), to: Benchee.System

    @doc """
    See `Benchee.Benchmark.benchmark/3`
    """
    defdelegate benchmark(suite, name, function), to: Benchee.Benchmark
    @doc false
    defdelegate benchmark(suite, name, function, printer), to: Benchee.Benchmark

    @doc """
    See `Benchee.Benchmark.collect/1`
    """
    defdelegate collect(suite), to: Benchee.Benchmark

    @doc false
    defdelegate collect(suite, printer), to: Benchee.Benchmark

    @doc """
    See `Benchee.Statistics.statistics/1`
    """
    defdelegate statistics(suite), to: Benchee.Statistics

    @doc """
    See `Benchee.RelativeStatistics.relative_statistics/1`
    """
    defdelegate relative_statistics(suite), to: Benchee.RelativeStatistics

    @doc """
    See `Benchee.ScenarioLoader.load/1`
    """
    defdelegate load(suite), to: Benchee.ScenarioLoader
  end
end
