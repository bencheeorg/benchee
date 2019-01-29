defmodule Benchee.Formatters.TaggedSaveTest do
  use ExUnit.Case

  alias Benchee.{
    Benchmark.Scenario,
    Formatter,
    Formatters.TaggedSave,
    Statistics,
    Suite
  }

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
        run_time_data: %{
          statistics: %Statistics{
            average: 200.0,
            ips: 5_000.0,
            std_dev_ratio: 0.1,
            median: 195.5,
            percentiles: %{99 => 400.1}
          }
        }
      },
      %Scenario{
        name: "First",
        job_name: "First",
        input_name: no_input(),
        input: no_input(),
        run_time_data: %{
          statistics: %Statistics{
            average: 100.0,
            ips: 10_000.0,
            std_dev_ratio: 0.1,
            median: 90.0,
            percentiles: %{99 => 300.1}
          }
        }
      }
    ]
  }

  @options %{
    path: @filename,
    tag: @benchee_tag
  }

  describe ".format/2" do
    test "able to restore the original just fine" do
      {binary, path} = format(@suite, @options)

      loaded_suite =
        binary
        |> :erlang.binary_to_term()
        |> suite_without_scenario_tags

      assert loaded_suite == @suite
      assert path == @filename
    end

    test "tags the scenarios and adds it to the name" do
      {binary, _path} = format(@suite, @options)

      loaded_suite = :erlang.binary_to_term(binary)

      Enum.each(loaded_suite.scenarios, fn scenario ->
        assert scenario.tag == @benchee_tag
        assert scenario.name =~ ~r/#{@benchee_tag}/
      end)
    end

    test "doesn't tag scenarios that already have a tag" do
      tagged_scenario = %Scenario{tag: "some-tag"}
      suite = %Suite{@suite | scenarios: [tagged_scenario | @suite.scenarios]}

      tags =
        suite
        |> scenarios_from_formatted
        |> sorted_tags

      assert tags == [@benchee_tag, "some-tag"]
    end

    test "when duplicating tags for the same job the second gets -2" do
      tagged_scenario = %Scenario{job_name: "foo", tag: @benchee_tag}
      scenario = %Scenario{job_name: "foo"}
      suite = %Suite{@suite | scenarios: [scenario, tagged_scenario]}

      scenarios = scenarios_from_formatted(suite)
      tags = sorted_tags(scenarios)
      names = sorted_names(scenarios)

      assert tags == [@benchee_tag, @benchee_tag <> "-2"]
      assert names == ["foo (#{@benchee_tag})", "foo (#{@benchee_tag}-2)"]
    end

    test "when there's already a -2 and -3 tag we end up with -4" do
      scenario_1 = %Scenario{job_name: "foo", tag: @benchee_tag}
      scenario_2 = %Scenario{job_name: "foo", tag: "#{@benchee_tag}-2"}
      scenario_3 = %Scenario{job_name: "foo", tag: "#{@benchee_tag}-3"}
      new_scenario = %Scenario{job_name: "foo"}

      suite = %Suite{@suite | scenarios: [scenario_1, new_scenario, scenario_2, scenario_3]}

      scenarios = scenarios_from_formatted(suite)
      tags = sorted_tags(scenarios)
      names = sorted_names(scenarios)

      assert tags ==
               [@benchee_tag, @benchee_tag <> "-2", @benchee_tag <> "-3", @benchee_tag <> "-4"]

      assert names == [
               "foo (#{@benchee_tag})",
               "foo (#{@benchee_tag}-2)",
               "foo (#{@benchee_tag}-3)",
               "foo (#{@benchee_tag}-4)"
             ]
    end

    defp scenarios_from_formatted(suite) do
      {binary, _path} = format(suite, @options)
      loaded_suite = :erlang.binary_to_term(binary)
      loaded_suite.scenarios
    end

    defp sorted_tags(scenarios) do
      scenarios
      |> Enum.map(fn scenario -> scenario.tag end)
      |> Enum.uniq()
      |> Enum.sort()
    end

    defp sorted_names(scenarios) do
      scenarios
      |> Enum.map(fn scenario -> scenario.name end)
      |> Enum.uniq()
      |> Enum.sort()
    end
  end

  describe "Integreating with Formatter.output/3" do
    test "able to restore fully from file" do
      capture_io(fn -> Formatter.output(@suite, TaggedSave, @options) end)

      etf_data = File.read!(@filename)

      loaded_suite =
        etf_data
        |> :erlang.binary_to_term()
        |> suite_without_scenario_tags

      assert loaded_suite == @suite
    after
      if File.exists?(@filename), do: File.rm!(@filename)
    end
  end
end
