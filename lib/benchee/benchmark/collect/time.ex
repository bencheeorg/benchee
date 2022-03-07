defmodule Benchee.Benchmark.Collect.Time do
  @moduledoc false

  # Measure the time elapsed while executing a given function.
  #
  # In contrast to `:timer.tc/1` it always returns the result in nano seconds instead of micro
  # seconds. This helps us avoid losing precision as both Linux and MacOSX seem to be able to
  # measure in nano seconds. `:timer.tc/n`
  # [forfeits this precision](
  # https://github.com/erlang/otp/blob/main/lib/stdlib/src/timer.erl#L164-L169).

  @behaviour Benchee.Benchmark.Collect

  @spec collect((() -> any)) :: {non_neg_integer, any}
  def collect(function) do
    start = :erlang.monotonic_time()
    result = function.()
    finish = :erlang.monotonic_time()

    duration_nano_seconds = :erlang.convert_time_unit(finish - start, :native, :nanosecond)

    {duration_nano_seconds, result}
  end
end
