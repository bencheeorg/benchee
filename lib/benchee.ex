# Idea from this:
# credo:disable-for-next-line
# https://github.com/bencheeorg/benchee/commit/b3ddbc132e641cdf1eec0928b322ced1dab8553f#commitcomment-23381474

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

    Benchmarks are defined as a map where the keys are a name for the given
    function and the values are the functions to benchmark. Users can configure
    the run by passing a keyword list as the second argument. For more
    information on configuration see `Benchee.Configuration.init/1`.

    ## Examples

        Benchee.run(
          %{
            "My Benchmark" => fn -> 1 + 1 end,
            "My other benchmrk" => fn -> [1] ++ [1] end
          },
          warmup: 2,
          time: 3
        )
    """
    @spec run(map, keyword) :: any
    def run(jobs, config \\ []) when is_list(config) do
      config
      |> Benchee.init()
      |> Benchee.system()
      |> add_benchmarking_jobs(jobs)
      |> Benchee.collect()
      |> Benchee.statistics()
      |> Benchee.load()
      |> Benchee.relative_statistics()
      |> Formatter.output()
      |> Benchee.profile()
    end

    defp add_benchmarking_jobs(suite, jobs) do
      Enum.reduce(jobs, suite, fn {key, function}, suite_acc ->
        Benchee.benchmark(suite_acc, key, function)
      end)
    end

    defdelegate init(), to: Benchee.Configuration
    defdelegate init(config), to: Benchee.Configuration
    defdelegate system(suite), to: Benchee.System
    defdelegate benchmark(suite, name, function), to: Benchee.Benchmark
    @doc false
    defdelegate benchmark(suite, name, function, printer), to: Benchee.Benchmark
    defdelegate collect(suite), to: Benchee.Benchmark
    @doc false
    defdelegate collect(suite, printer), to: Benchee.Benchmark
    defdelegate statistics(suite), to: Benchee.Statistics
    defdelegate relative_statistics(suite), to: Benchee.RelativeStatistics
    defdelegate load(suite), to: Benchee.ScenarioLoader
    defdelegate profile(suite), to: Benchee.Profile
  end
end
