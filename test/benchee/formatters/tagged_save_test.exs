defmodule Benchee.Formatters.TaggedSaveTest do
  use ExUnit.Case

  alias Benchee.{Suite, Statistics}
  alias Benchee.Benchmark.Scenario
  import Benchee.Formatters.TaggedSave
  import Benchee.Benchmark, only: [no_input: 0]
  import ExUnit.CaptureIO
  import Benchee.TestHelpers, only: [suite_without_scenario_tags: 1]

  @filename "test/tmp/some_file.etf"
  @benchee_tag "benchee-tag"
  @suite %Suite{
    scenarios: [
      %Scenario{
        name: "Second",
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
        name: "First",
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
      formatter_options: %{
        tagged_save: %{
          file: @filename,
          tag: @benchee_tag
        }
      }
    }
  }


  describe ".format/1" do
    test "able to restore the original just fine" do
      {binary, path} = format(@suite)

      loaded_suite = binary
                     |> :erlang.binary_to_term
                     |> suite_without_scenario_tags

      assert loaded_suite == @suite
      assert path == @filename
    end

    test "tags the scenarios and adds it to the name" do
      {binary, _path} = format(@suite)

      loaded_suite = :erlang.binary_to_term(binary)

      Enum.each loaded_suite.scenarios, fn(scenario) ->
        assert scenario.tag == @benchee_tag
        assert scenario.name =~ ~r/#{@benchee_tag}/
      end
    end

    test "doesn't tag scenarios that already had a tag" do
      tagged_scenario = %Scenario{tag: "some-tag"}
      suite = %Suite{@suite | scenarios: [tagged_scenario | @suite.scenarios]}

      {binary, _path} = format(suite)
      loaded_suite = :erlang.binary_to_term(binary)
      loaded_scenarios = loaded_suite.scenarios

      tags = loaded_scenarios
             |> Enum.map(fn(scenario) -> scenario.tag end)
             |> Enum.uniq
             |> Enum.sort

      assert tags == [@benchee_tag, "some-tag"]
    end
  end

  describe ".output/1" do
    test "able to restore fully from file" do
      try do
        capture_io fn -> output(@suite) end

        etf_data = File.read!(@filename)

        loaded_suite = etf_data
                       |> :erlang.binary_to_term
                       |> suite_without_scenario_tags

        assert loaded_suite == @suite
      after
        if File.exists?(@filename), do: File.rm!(@filename)
      end
    end
  end
end
