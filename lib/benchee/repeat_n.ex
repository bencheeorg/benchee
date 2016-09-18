defmodule Benchee.RepeatN do
  @moduledoc """
  Simple helper module that can easily make a function call repeat n times.
  Which is significantly faster than Enum.each/list comprehension.

  Check out the benchmark in `samples/repeat_n.exs`
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
