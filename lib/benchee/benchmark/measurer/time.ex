defmodule Benchee.Benchmark.Measurer.Time do
  @moduledoc """
  Measure the time consumed by a executing function.
  """

  @behaviour Benchee.Benchmark.Measurer

  def measure(function) do
    :timer.tc(function)
  end
end
