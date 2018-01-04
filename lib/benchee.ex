# Idea from this:
# credo:disable-for-next-line
# https://github.com/PragTob/benchee/commit/b3ddbc132e641cdf1eec0928b322ced1dab8553f#commitcomment-23381474

elixir_doc = """
Top level module providing convenience access to needed functions as well
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
      # pre 0.6.0 way of passing in the config first and as a map
      do_run(jobs, config)
    end

    defp do_run(jobs, config) do
      jobs
      |> run_benchmarks(config)
      |> output_results
    end

    defp run_benchmarks(jobs, config) do
      config
      |> Benchee.init
      |> Benchee.system
      |> add_benchmarking_jobs(jobs)
      |> Benchee.measure
      |> Benchee.statistics
      |> Benchee.load
    end

    defp output_results(suite = %{configuration: %{formatters: formatters}}) do
      # Can be replaced with `split_with` once we deprecate elixir 1.3
      {parallelizable, serial} =
        Enum.split_with(formatters, &is_formatter_module?/1)

      # why do we ignore this suite? It shouldn't be changed anyway.
      _suite = Formatter.parallel_output(suite, parallelizable)
      Enum.each serial, fn(output_function) ->
        output_function.(suite)
      end

      suite
    end

    defp is_formatter_module?(formatter) when is_atom(formatter) do
      module_attributes = formatter.module_info(:attributes)

      module_attributes
      |> Keyword.get(:behaviour, [])
      |> Enum.member?(Benchee.Formatter)
    end
    defp is_formatter_module?(_), do: false

    defp add_benchmarking_jobs(suite, jobs) do
      Enum.reduce jobs, suite, fn({key, function}, suite_acc) ->
        Benchee.benchmark(suite_acc, key, function)
      end
    end

    defdelegate init(),                           to: Benchee.Configuration
    defdelegate init(config),                     to: Benchee.Configuration
    defdelegate system(suite),                    to: Benchee.System
    defdelegate measure(suite),                   to: Benchee.Benchmark
    defdelegate measure(suite, printer),          to: Benchee.Benchmark
    defdelegate benchmark(suite, name, function), to: Benchee.Benchmark
    defdelegate statistics(suite),                to: Benchee.Statistics
    defdelegate load(suite),                      to: Benchee.ScenarioLoader
    defdelegate benchmark(suite, name, function, printer), to: Benchee.Benchmark
  end
end
