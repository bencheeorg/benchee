defmodule Benchee.Output.BenchmarkPrinter do
  @moduledoc false

  alias Benchee.Benchmark
  alias Benchee.Conversion.Duration
  alias Benchee.System

  @doc """
  Shown when you try benchmark an evaluated function.

  Compiled functions should be preferred as they are less likely to introduce additional overhead to your benchmark timing.
  """
  def evaluated_function_warning(job_name) do
    IO.puts("""
    Warning: the benchmark #{job_name} is using an evaluated function.
      Evaluated functions perform slower than compiled functions.
      You can move the Benchee caller to a function in a module and invoke `Mod.fun()` instead.
      Alternatively, you can move the benchmark into a benchmark.exs file and run mix run benchmark.exs
    """)
  end

  @doc """
  Shown when you try to define a benchmark with the same name twice.

  How would you want to discern those anyhow?
  """
  def duplicate_benchmark_warning(name) do
    IO.puts(
      "You already have a job defined with the name \"#{name}\", you can't add two jobs with the same name!"
    )
  end

  @doc """
  Prints general information such as system information and estimated
  benchmarking time.
  """
  def configuration_information(%{configuration: %{print: %{configuration: false}}}) do
    nil
  end

  def configuration_information(%{scenarios: scenarios, system: sys, configuration: config}) do
    system_information(sys)
    suite_information(scenarios, config)
  end

  defp system_information(%System{
         erlang: erlang_version,
         elixir: elixir_version,
         jit_enabled?: jit_enabled?,
         os: os,
         num_cores: num_cores,
         cpu_speed: cpu_speed,
         available_memory: available_memory
       }) do
    IO.puts("""
    Operating System: #{os}
    CPU Information: #{cpu_speed}
    Number of Available Cores: #{num_cores}
    Available memory: #{available_memory}
    Elixir #{elixir_version}
    Erlang #{erlang_version}
    JIT enabled: #{jit_enabled?}
    """)
  end

  defp suite_information(scenarios, %{
         parallel: parallel,
         time: time,
         warmup: warmup,
         inputs: inputs,
         memory_time: memory_time,
         reduction_time: reduction_time
       }) do
    scenario_count = length(scenarios)
    exec_time = warmup + time + memory_time + reduction_time
    total_time = scenario_count * exec_time

    IO.puts("""
    Benchmark suite executing with the following configuration:
    warmup: #{Duration.format_human(warmup)}
    time: #{Duration.format_human(time)}
    memory time: #{Duration.format_human(memory_time)}
    reduction time: #{Duration.format_human(reduction_time)}
    parallel: #{parallel}
    inputs: #{inputs_out(inputs)}
    Estimated total run time: #{Duration.format_human(total_time)}
    """)
  end

  defp inputs_out(nil), do: "none specified"

  defp inputs_out(inputs) do
    Enum.map_join(inputs, ", ", fn {name, _} -> name end)
  end

  @doc """
  Prints a notice which job is currently being benchmarked.
  """
  def benchmarking(_, _, %{print: %{benchmarking: false}}), do: nil

  def benchmarking(name, input_name, config) do
    time_configs = [config.time, config.warmup, config.memory_time, config.reduction_time]

    if Enum.all?(time_configs, fn time -> time == 0 end) do
      nil
    else
      IO.puts("Benchmarking #{name}#{input_information(input_name)} ...")
    end
  end

  @no_input Benchmark.no_input()
  defp input_information(@no_input), do: ""
  defp input_information(input_name), do: " with input #{input_name}"

  @doc """
  Prints a warning about accuracy of benchmarks when the function is super fast.
  """
  def fast_warning do
    IO.puts("""
    Warning: The function you are trying to benchmark is super fast, making measurements more unreliable!
    This holds especially true for memory measurements or when running with hooks.

    See: https://github.com/bencheeorg/benchee/wiki/Benchee-Warnings#fast-execution-warning

    You may disable this warning by passing print: [fast_warning: false] as configuration options.
    """)
  end

  @doc """
  Print the measured function call overhead.
  """
  @spec function_call_overhead(non_neg_integer()) :: :ok
  def function_call_overhead(overhead) do
    scaled_overhead = Duration.scale(overhead)

    IO.puts("Measured function call overhead as: #{Duration.format(scaled_overhead)}")
  end
end
