defmodule Benchee.Test.FakeProfilePrinter do
  @moduledoc false

  def profiling(name, profiler) do
    send(self(), {:profiling, name, profiler})
  end
end
