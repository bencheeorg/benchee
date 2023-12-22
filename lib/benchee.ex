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
    @spec run(map, keyword) :: Benchee.Suite.t()
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

    @doc """
    A convenience function designed for loading saved benchmarks and running formatters on them.

    Basically takes the input of the map of jobs away from you and skips unnecessary steps with
    that data missing (aka not running benchmarks, only running relative statistics).

    You can use config options as normal, but some options related to benchmarking won't take
    effect (such as `:time`). The `:load` option however is mandatory to use, as you need to
    load some benchmarks to report on them.

    ## Usage

        Benchee.report(load: ["benchmark-*.benchee"])
    """
    @spec report(keyword) :: Benchee.Suite.t()
    def report(config) do
      unless Access.get(config, :load), do: raise_missing_load()

      config
      |> Benchee.init()
      |> Benchee.system()
      |> Benchee.load()
      |> Benchee.relative_statistics()
      |> Formatter.output()
    end

    defp raise_missing_load do
      raise ArgumentError,
            "You need to provide at least a :load option for report/1 to make sense"
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
    @doc false
    defdelegate statistics(suite, printer), to: Benchee.Statistics
    defdelegate relative_statistics(suite), to: Benchee.RelativeStatistics
    defdelegate load(suite), to: Benchee.ScenarioLoader
    defdelegate profile(suite), to: Benchee.Profile
  end
end
