defmodule Benchee.Output.ProfilePrinter do
  @moduledoc false

  @doc """
  Prints a notification of which job is being profiled.
  """
  def profiling(name, profiler) do
    IO.puts("\nProfiling #{name} with #{profiler}...")
  end
end
