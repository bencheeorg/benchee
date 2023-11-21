defmodule Benchee.Output.ProgressPrinter do
  @moduledoc false

  def calculating_statistics(%{print: %{benchmarking: false}}), do: nil

  def calculating_statistics(_config) do
    IO.puts("Calculating statistics...")
  end

  def formatting(%{print: %{benchmarking: false}}), do: nil

  def formatting(_config) do
    IO.puts("Formatting results...")
  end
end
