defmodule Benchee.Benchmark do
  @moduledoc """
  Functionality related to the actual benchmarking. Meaning running the
  given functions and recording their individual run times in a list.
  Exposes `benchmark` function.
  """

  alias Benchee.Suite
  alias Benchee.Benchmark.Runner
  alias Benchee.Output.BenchmarkPrinter, as: Printer

  @type name :: String.t

  defstruct [:name, :input, :input_name, :function, :printer, :config,
             :run_times, :memory_usage]

  @doc """
  Adds the given function and its associated name to the benchmarking jobs to
  be run in this benchmarking suite as a tuple `{name, function}` to the list
  under the `:jobs` key.
  """
  @spec benchmark(Suite.t, name, fun, module) :: Suite.t
  def benchmark(suite = %Suite{jobs: jobs}, name, function, printer \\ Printer) do
    normalized_name = to_string(name)
    if Map.has_key?(jobs, normalized_name) do
      printer.duplicate_benchmark_warning normalized_name
      suite
    else
      %Suite{suite | jobs: Map.put(jobs, normalized_name, function)}
    end
  end


  @doc """
  Executes the benchmarks defined before by first running the defined functions
  for `warmup` time without gathering results and them running them for `time`
  gathering their run times.

  This means the total run time of a single benchmarking job is warmup + time.

  Warmup is usually important for run times with JIT but it seems to have some
  effect on the BEAM as well.

  There will be `parallel` processes spawned exeuting the benchmark job in
  parallel.
  """
  @spec measure(Suite.t, module) :: Suite.t
  def measure(suite = %Suite{jobs: jobs, configuration: config}, printer \\ Printer) do
    printer.configuration_information(suite)
    benchmarks = build_benchmarks(jobs, config, printer)
    benchmarks_with_results = Runner.run_benchmarks(benchmarks)

    %Suite{suite | benchmarks: benchmarks_with_results}
  end

  @no_input :__no_input
  @no_input_marker {@no_input, @no_input}
  def no_input, do: @no_input

  defp build_benchmarks(jobs, config = %{inputs: nil}, printer) do
    benchmarks_for_input(@no_input_marker, jobs, config, printer)
  end
  defp build_benchmarks(jobs, config = %{inputs: inputs}, printer) do
    Enum.flat_map(inputs, fn(input) ->
      benchmarks_for_input(input, jobs, config, printer)
    end)
  end

  defp benchmarks_for_input({input_name, input}, jobs, config, printer) do
    Enum.map(jobs, fn({name, function}) ->
      %__MODULE__{name: name, function: function, config: config,
                  input_name: input_name, input: input, printer: printer}
    end)
  end
end
