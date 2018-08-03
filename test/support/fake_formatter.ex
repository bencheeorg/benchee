defmodule Benchee.Test.FakeFormatter do
  @moduledoc false

  use Benchee.Formatter

  def format(_, opts) do
    "output of `format/1` with #{inspect(opts)}"
  end

  def write(output, _) do
    send(self(), {:write, output})
  end
end
