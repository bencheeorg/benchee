defmodule Benchee.Benchmark.FunctionCallOverhead do
  @moduledoc false

  alias Benchee.Benchmark.Collect.Time
  alias Benchee.Conversion

  @overhead_determination_time Conversion.Duration.convert_value({0.01, :second}, :nanosecond)

  # Compute the function call overhead on the current system
  #
  # You might wonder why this isn't done simply through using our existing infrastructure
  # and just run it with Scenario, Context etc. - in fact that's how it used to be,
  # but it meant that we'd pass half-baked scenarios to functions causing dialyzer to complain,
  # as well as running for a lot more code than we strictly need to like the
  # `determine_n_times` code that we should rather not go through as it changes
  # what this function does.
  # This also gives us a way to make sure we definitely take at least one measurement.
  @spec measure() :: non_neg_integer()
  def measure do
    # just the fastest function one can think of...
    overhead_function = fn -> nil end

    _ = warmup(overhead_function)
    run_times = run(overhead_function)

    Statistex.minimum(run_times)
  end

  defp warmup(function) do
    run_for(function, @overhead_determination_time / 2)
  end

  defp run(function) do
    run_for(function, @overhead_determination_time)
  end

  defp run_for(function, run_time) do
    end_time = current_time() + run_time

    do_run(function, [], end_time)
  end

  @spec do_run((() -> any), [number], number) :: [number, ...]
  defp do_run(function, durations, end_time) do
    {duration, _} = Time.collect(function)

    if current_time() < end_time do
      do_run(function, [duration | durations], end_time)
    else
      durations
    end
  end

  defp current_time, do: :erlang.system_time(:nano_seconds)
end
