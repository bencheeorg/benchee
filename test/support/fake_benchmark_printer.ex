defmodule Benchee.Test.FakeBenchmarkPrinter do
  def configuration_information(_) do
    send self(), :configuration_information
  end

  def benchmarking(name, _) do
    send self(), {:benchmarking, name}
  end

  def fast_warning do
    send self(), :fast_warning
  end

  def input_information(name) do
    send self(), {:input_information, name}
  end
end
