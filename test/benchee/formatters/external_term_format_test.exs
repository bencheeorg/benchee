defmodule Benchee.Formatters.ExternalTermFormatTest do
  use ExUnit.Case

  alias Benchee.{Suite, Statistics}
  alias Benchee.Benchmark.Scenario
  import Benchee.Formatters.ExternalTermFormat
  import Benchee.Benchmark, only: [no_input: 0]
  import ExUnit.CaptureIO

  @filename "some_file.etf"
  @suite %Suite{
    scenarios: [
      %Scenario{
        job_name: "Second",
        input_name: no_input(),
        input: no_input(),
        run_time_statistics: %Statistics{
          average: 200.0,
          ips: 5_000.0,
          std_dev_ratio: 0.1,
          median: 195.5,
          percentiles: %{99 => 400.1}
        }
      },
      %Scenario{
        job_name: "First",
        input_name: no_input(),
        input: no_input(),
        run_time_statistics: %Statistics{
           average: 100.0,
           ips: 10_000.0,
           std_dev_ratio: 0.1,
           median: 90.0,
           percentiles: %{99 => 300.1}
         }
      }
    ],
    configuration: %Benchee.Configuration{
      formatter_options: %{external_term_format: %{file: @filename}}
    }
  }


  describe ".format/1" do
    test "able to restore the original just fine" do
      {binary, path} = format(@suite)

      assert :erlang.binary_to_term(binary) == @suite
      assert path == @filename
    end
  end

  describe ".output/1" do
    test "able to restore fully from file" do
      try do
        capture_io fn -> output(@suite) end

        etf_data = File.read!(@filename)

        assert :erlang.binary_to_term(etf_data) == @suite
      after
        if File.exists?(@filename), do: File.rm!(@filename)
      end
    end
  end
end
