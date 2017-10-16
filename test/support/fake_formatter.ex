defmodule Benchee.Test.FakeFormatter do
  @behaviour Benchee.Formatter

  def format(_) do
    "output of `format/1`"
  end

  def write(output) do
    send self(), {:write, output}
  end

  def output(suite) do
    :ok = suite
          |> format
          |> write

    suite
  end

end
