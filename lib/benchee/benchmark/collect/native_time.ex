defmodule Benchee.Benchmark.Collect.NativeTime do
  @moduledoc false

  # Measure the time elapsed while executing a given function.
  #
  # Uses only the time unit native to the platform. Used for determining how many times a function
  # should be repeated in `Benchee.Benchmark.Runner.determine_n_times/3` (private method though).

  @behaviour Benchee.Benchmark.Collect

  def collect(function) do
    start = :erlang.monotonic_time()
    result = function.()
    finish = :erlang.monotonic_time()

    {finish - start, result}
  end
end
