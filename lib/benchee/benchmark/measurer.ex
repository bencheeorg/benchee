defmodule Benchee.Benchmark.Measurer do
  @moduledoc """
  A thing that measures something about a function execution - like time or
  memory needed.

  Callback is `measure` which takes an anonymous 0 arity function to measure
  and returns the measurement and the return value of the function in a tuple.
  """
  @callback measure((() -> any)) :: {non_neg_integer, any}
end
