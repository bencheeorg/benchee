defmodule Benchee.Test.FakeFormatter do
  @moduledoc false

  @behaviour Benchee.Formatter

  def format(_, options) do
    "output of `format/1` with #{inspect(options)}"
  end

  def write(output, options) do
    send(self(), {:write, output, options})
  end
end
