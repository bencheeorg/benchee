defmodule Benchee.Output.BenchmarkPrinter do
  @moduledoc """
  Printing happening during the Benchmark stage.
  """

  alias Benchee.Conversion.Duration

  @doc """
  Shown when you try to define a benchmark with the same name twice.

  How would you want to discern those anyhow?
  """
  def duplicate_benchmark_warning(name) do
    IO.puts "You already have a job defined with the name \"#{name}\", you can't add two jobs with the same name!"
  end

  @doc """
  Prints general information such as system information and estimated
  benchmarking time.
  """
  def configuration_information(%{configuration: %{print: %{configuration: false}}}) do
    nil
  end
  def configuration_information(%{jobs: jobs, system: sys, configuration: config}) do
    system_information(sys)
    suite_information(jobs, config)
  end

  defp system_information(%{erlang: erlang_version, elixir: elixir_version}) do
    IO.puts "Elixir #{elixir_version}"
    IO.puts "Erlang #{erlang_version}"
  end

  defp suite_information(jobs, %{parallel: parallel,
                                 time:     time,
                                 warmup:   warmup,
                                 inputs:   inputs}) do
    warmup_seconds = time_precision Duration.scale(warmup, :second)
    time_seconds   = time_precision Duration.scale(time, :second)
    job_count      = map_size jobs
    exec_time      = warmup_seconds + time_seconds
    total_time     = time_precision(job_count * inputs_count(inputs) * exec_time)

    IO.puts "Benchmark suite executing with the following configuration:"
    IO.puts "warmup: #{warmup_seconds}s"
    IO.puts "time: #{time_seconds}s"
    IO.puts "parallel: #{parallel}"
    IO.puts "inputs: #{inputs_out(inputs)}"
    IO.puts "Estimated total run time: #{total_time}s"
    IO.puts ""
  end

  defp inputs_count(nil),    do: 1 # no input specified still executes
  defp inputs_count(inputs), do: map_size(inputs)

  defp inputs_out(nil), do: "none specified"
  defp inputs_out(inputs) do
    inputs
    |> Map.keys
    |> Enum.join(", ")
  end

  @round_precision 2
  defp time_precision(float) do
    Float.round(float, @round_precision)
  end

  @doc """
  Prints a notice which job is currently being benchmarked.
  """
  def benchmarking(_, %{print: %{benchmarking: false}}), do: nil
  def benchmarking(name, _config) do
    IO.puts "Benchmarking #{name}..."
  end

  @doc """
  Prints a warning about accuracy of benchmarks when the function is super fast.
  """
  def fast_warning do
    IO.puts """
    Warning: The function you are trying to benchmark is super fast, making measures more unreliable! See: https://github.com/PragTob/benchee/wiki/Benchee-Warnings#fast-execution-warning

    You may disable this warning by passing print: [fast_warning: false] as
    configuration options.
    """
  end

  @doc """
  Prints an informative message about which input is currently being
  benchmarked, when multiple inputs were specified.
  """
  def input_information(_, %{print: %{benchmarking: false}}) do
    nil
  end
  def input_information(input_name, _config) do
    if input_name != Benchee.Benchmark.no_input do
      IO.puts "\nBenchmarking with input #{input_name}:"
    end
  end

end
