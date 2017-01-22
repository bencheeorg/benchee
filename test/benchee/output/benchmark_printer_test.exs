defmodule Benchee.Output.BenchmarkPrintertest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  import Benchee.Output.BenchmarkPrinter

  test ".configuration_information sys information" do
    output = capture_io fn ->
      %{
        config: %{parallel: 2, time: 10_000, warmup: 0, inputs: nil},
        jobs: %{"one" => nil, "two" => nil},
        system: %{elixir: "1.4", erlang: "19.2"}
      }
      |> configuration_information
    end

    assert output =~ "Erlang 19.2"
    assert output =~ "Elixir 1.4"
    assert output =~ ~r/following configuration/i
    assert output =~ "warmup: 0.0s"
    assert output =~ "time: 0.01s"
    assert output =~ "parallel: 2"
    assert output =~ "Estimated total run time: 0.02s"
  end

  @inputs %{"Arg 1" => "Argument 1", "Arg 2" => "Argument 2"}
  test ".configuration_information multiple inputs" do
    output = capture_io fn ->
      %{
        config: %{parallel: 2, time: 10_000, warmup: 0, inputs: @inputs},
        jobs: %{"one" => nil, "two" => nil},
        system: %{elixir: "1.4", erlang: "19.2"}
      }
      |> configuration_information
    end

    assert output =~ "time: 0.01s"
    assert output =~ "parallel: 2"
    assert output =~ "inputs: Arg 1, Arg 2"
    assert output =~ "Estimated total run time: 0.04s"
  end

  test ".configuration_information does not print if disabled" do
    output = capture_io fn ->
      %{config: %{print: %{configuration: false}}}
      |> configuration_information
    end

    assert output == ""
  end

  test ".benchmarking prints information that it's currently benchmarking" do
    output = capture_io fn ->
      benchmarking("Something", %{})
    end

    assert output =~ ~r/Benchmarking.+Something/i
  end

  test ".benchmarking doesn't print if it's deactivated" do
    output = capture_io fn ->
      benchmarking "A", %{print: %{benchmarking: false}}
    end

    assert output == ""
  end

  test ".input_information notifies of the input being used" do
    output = capture_io fn ->
      input_information("Big List")
    end

    assert output =~ ~r/with input Big List/i
  end

  test ".input_information does nothing when it's the no input marker" do
    marker = Benchee.Benchmark.no_input
    output = capture_io fn ->
      input_information marker
    end

    assert output == ""
  end

  test ".fast_warning warns with reference" do
    output = capture_io fn ->
      fast_warning()
    end

    assert output =~ ~r/fast/i
    assert output =~ ~r/unreliable/i
    assert output =~ "benchee/wiki"

  end
end
