defmodule Benchee.Benchmark.Measure do
  @moduledoc """
  A thing that measures something about a function execution - like time or
  memory needed.
  """

  @doc """
  Takes an anonymous 0 arity function to measure and returns the measurement
  and the return value of the function in a tuple.

  The returned measurement may be `nil` if the measurement failed for some
  reason - it will then be ignored and not counted.
  """
  @callback measure((() -> any)) :: {non_neg_integer | nil, any}
end
