defmodule Benchee.Benchmark.Collect.ReturnValue do
  @moduledoc false

  # Returns the value of the evaluated function.
  # Used for pre checks.

  @behaviour Benchee.Benchmark.Collect

  @spec collect((-> any)) :: {any, any}
  def collect(function) do
    result = function |> Task.async() |> Task.await(:infinity)
    {result, result}
  end
end
