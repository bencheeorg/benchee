defmodule Benchee.Test.FakeProgressPrinter do
  @moduledoc false

  def calculating_statistics(_) do
    send(self(), :calculating_statistics)
  end

  def formatting(_) do
    send(self(), :formatting)
  end
end
