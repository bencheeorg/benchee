defmodule Benchee.Test.FakeFormatter do
  @moduledoc false

  use Benchee.Formatter

  def format(_, _) do
    "output of `format/1`"
  end

  def write(output, _) do
    send(self(), {:write, output})
  end
end
