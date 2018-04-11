defmodule Benchee.Benchmark.Measure.Time do
  @moduledoc """
  Measure the time consumed by a executing function.
  """

  @behaviour Benchee.Benchmark.Measure

  def measure(function) do
    :timer.tc(function)
  end
end
