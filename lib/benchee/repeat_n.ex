defmodule Benchee.RepeatN do
  @moduledoc """
  Simple helper module that can easily make a function call repeat n times.
  Which is significantly faster than Enum.each/list comprehension.

  Check out the benchmark in samples/repeat_n.exs:

      Name                          ips            average        deviation      median
      Recursion                     76037.28       13.15μs        (±10.76%)      13.0μs
      Enum.each                     54930.00       18.20μs        (±22.01%)      18.0μs
      List comprehension            46742.24       21.39μs        (±20.72%)      21.0μs

      Comparison:
      Recursion                     76037.28
      Enum.each                     54930.00        - 1.38x slower
      List comprehension            46742.24        - 1.63x slower
  """

  @doc """
  Calls the given function n times.
  """
  def repeat_n(_function, 0) do
    # noop
  end
  def repeat_n(function, 1) do
    function.()
  end
  def repeat_n(function, count) do
    function.()
    repeat_n(function, count - 1)
  end
end
