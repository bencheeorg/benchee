defmodule Benchee.Utility.RepeatN do
  @moduledoc false

  @doc """
  Calls the given function n times.
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
