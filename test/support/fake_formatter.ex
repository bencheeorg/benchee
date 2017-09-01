defmodule Benchee.Test.FakeFormatter do
  def format(_) do
    "output of `format/1`"
  end

  def write(output) do
    send self(), {:write, output}
  end
end
