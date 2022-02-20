defmodule Benchee.Benchmark.Collect do
  @moduledoc false

  # A thing that collects a data point about a function execution - like time
  # or memory needed.

  @doc """
  Takes an anonymous 0 arity function to measure and returns the measurement
  and the return value of the function in a tuple.

  The returned measurement may be `nil` if the measurement failed for some
  reason - it will then be ignored and not counted.
  """
  @type return_value :: {non_neg_integer | nil, any}
  @type zero_arity_function :: (() -> any)
  @type opts :: any
  @callback collect(zero_arity_function()) :: return_value()
  @callback collect(zero_arity_function(), opts) :: return_value()

  @optional_callbacks collect: 2
end
