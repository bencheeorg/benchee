defmodule Benchee.TestHelpers do
  # retry tests that are doing actual benchmarking and are flaky
  # on overloaded and/or slower systems
  def retrying(asserting_function, n \\ 5)
  def retrying(asserting_function, 1) do
    asserting_function.()
  end
  def retrying(asserting_function, n) do
    try do
      asserting_function.()
    rescue
      ExUnit.AssertionError ->
        retrying(asserting_function, n - 1)
    end
  end
end
