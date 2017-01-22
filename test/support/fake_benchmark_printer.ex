defmodule Benchee.Test.FakeBenchmarkPrinter do
  def duplicate_benchmark_warning(name) do
    send self(), {:duplicate, name}
  end

  def configuration_information(_) do
    send self(), :configuration_information
  end

  def benchmarking(name, _) do
    send self(), {:benchmarking, name}
  end

  def fast_warning do
    send self(), :fast_warning
  end

  def input_information(name, _config) do
    send self(), {:input_information, name}
  end
end
