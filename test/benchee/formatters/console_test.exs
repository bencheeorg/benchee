defmodule Benchee.Formatters.ConsoleTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  import Benchee.Benchmark, only: [no_input: 0]
  doctest Benchee.Formatters.Console

  alias Benchee.Formatters.Console
  alias Benchee.{Suite, Statistics, Benchmark.Scenario}

  @console_config %{
    comparison: true,
    unit_scaling: :best,
    extended_statistics: false
  }
  @console_config_extended_params %{
    comparison: true,
    unit_scaling: :best,
    extended_statistics: true
  }
  @config %Benchee.Configuration{
    formatter_options: %{
      console: %{
        comparison: true,
        extended_statistics: false
      }
    }
  }
  describe ".output" do
    test "formats and prints the results right to the console" do
      scenarios = [
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
      ]

      output = capture_io fn ->
        Console.output %Suite{scenarios: scenarios, configuration: @config}
      end

      assert output =~ ~r/First/
      assert output =~ ~r/Second/
      assert output =~ ~r/200/
      assert output =~ ~r/5 K/
      assert output =~ ~r/10.00%/
      assert output =~ ~r/195.5/
      assert output =~ ~r/300.1/
      assert output =~ ~r/400.1/
    end
  end

  describe ".format_scenarios" do
    test "displays extended statistics" do
      scenarios = [
        %Scenario{
          job_name: "First job",
          run_time_statistics: %Statistics{
            average: 200.0,
            ips: 5_000.0,
            std_dev_ratio: 0.1,
            median: 195.5,
            percentiles: %{99 => 300.1},
            minimum: 111.1,
            maximum: 333.3,
            mode: 201.2,
            sample_size: 50_000
          }
        }
      ]

      [_header1, _result1, header1, header2, result2] =
        Console.format_scenarios(scenarios, @console_config_extended_params)

        assert header1 =~ ~r/Extended statistics: /
        assert header2 =~ ~r/minimum/
        assert header2 =~ ~r/maximum/
        assert header2 =~ ~r/sample size/
        assert header2 =~ ~r/mode/
        assert result2 =~ ~r/First job/
        assert result2 =~ ~r/111.10/
        assert result2 =~ ~r/333.30/
        assert result2 =~ ~r/50 K/
        assert result2 =~ ~r/201.20/
    end

    test "displays extended statistics with multiple mode ouput" do
      scenarios = [
        %Scenario{
          job_name: "First job",
          run_time_statistics: %Statistics{
            average: 200.0,
            ips: 5_000.0,
            std_dev_ratio: 0.1,
            median: 195.5,
            percentiles: %{99 => 300.1},
            minimum: 111.1,
            maximum: 333.3,
            mode: [201.2, 205.55],
            sample_size: 50_000
          }
        }
      ]

      [_header1, _result1, _header2, _header3, result2] =
        Console.format_scenarios(scenarios, @console_config_extended_params)

        assert result2 =~ ~r/201.20 μs/
        assert result2 =~ ~r/205.55 μs/
    end

    test "displays N/A when no mode exists" do
      scenarios = [
        %Scenario{
          job_name: "First job",
          run_time_statistics: %Statistics{
            average: 200.0,
            ips: 5_000.0,
            std_dev_ratio: 0.1,
            median: 195.5,
            percentiles: %{99 => 300.1},
            minimum: 111.1,
            maximum: 333.3,
            sample_size: 50_000
          }
        }
      ]

      [_header1, _result1, _header2, _header3, result2] =
        Console.format_scenarios(scenarios, @console_config_extended_params)

        assert result2 =~ ~r/None/
    end

    test "sorts the the given stats fastest to slowest" do
      scenarios = [
        %Scenario{
          job_name: "Second",
          run_time_statistics: %Statistics{
            average: 200.0,
            ips: 5_000.0,
            std_dev_ratio: 0.1,
            median: 195.5,
            percentiles: %{99 => 300.1}
          }
        },
        %Scenario{
          job_name: "Third",
          run_time_statistics: %Statistics{
            average: 400.0,
            ips: 2_500.0,
            std_dev_ratio: 0.1,
            median: 375.0,
            percentiles: %{99 => 400.1}
          }
        },
        %Scenario{
          job_name: "First",
          run_time_statistics: %Statistics{
            average: 100.0,
            ips: 10_000.0,
            std_dev_ratio: 0.1,
            median: 90.0,
            percentiles: %{99 => 200.1}
          }
        },
      ]

      [_header, result_1, result_2, result_3 | _dont_care] =
        Console.format_scenarios(scenarios, @console_config)

      assert Regex.match?(~r/First/,  result_1)
      assert Regex.match?(~r/Second/, result_2)
      assert Regex.match?(~r/Third/,  result_3)
    end

    test "adjusts the label width to longest name" do
      scenarios = [
        %Scenario{
          job_name: "Second",
          run_time_statistics: %Statistics{
            average: 400.0,
            ips: 2_500.0,
            std_dev_ratio: 0.1,
            median: 375.0,
            percentiles: %{99 => 400.1}
          }
        },
        %Scenario{
          job_name: "First",
          run_time_statistics: %Statistics{
            average: 200.0,
            ips: 5_000.0,
            std_dev_ratio: 0.1,
            median: 195.5,
            percentiles: %{99 => 300.1}
          }
        }
      ]

      expected_width = String.length "Second"
      [header, result_1, result_2 | _dont_care] =
        Console.format_scenarios(scenarios, @console_config)

      assert_column_width "Name", header, expected_width
      assert_column_width "First", result_1, expected_width
      assert_column_width "Second", result_2, expected_width

      third_length = 40
      third_name = String.duplicate("a", third_length)
      long_scenario = %Scenario{
        job_name: third_name,
        run_time_statistics: %Statistics{
          average: 400.1,
          ips: 2_500.0,
          std_dev_ratio: 0.1,
          median: 375.0,
          percentiles: %{99 => 500.1}
        }
      }
      longer_scenarios = scenarios ++ [long_scenario]

      # Include extra long name, expect width of 40 characters
      [header, result_1, result_2, result_3 | _dont_care] =
        Console.format_scenarios(longer_scenarios, @console_config)

      assert_column_width "Name", header, third_length
      assert_column_width "First", result_1, third_length
      assert_column_width "Second", result_2, third_length
      assert_column_width third_name, result_3, third_length
    end

    test "creates comparisons" do
      scenarios = [
        %Scenario{
          job_name: "Second",
          run_time_statistics: %Statistics{
            average: 200.0,
            ips: 5_000.0,
            std_dev_ratio: 0.1,
            median: 195.5,
            percentiles: %{99 => 500.1}
          }
        },
        %Scenario{
          job_name: "First",
          run_time_statistics: %Statistics{
            average: 100.0,
            ips: 10_000.0,
            std_dev_ratio: 0.1,
            median: 90.0,
            percentiles: %{99 => 500.1}
          }
        }
      ]

      [_, _, _, comp_header, reference, slower] =
        Console.format_scenarios(scenarios, @console_config)

      assert Regex.match? ~r/Comparison/, comp_header
      assert Regex.match? ~r/^First\s+10 K$/m, reference
      assert Regex.match? ~r/^Second\s+5 K\s+- 2.00x slower/, slower
    end

    test "can omit the comparisons" do
      scenarios = [
        %Scenario{
          job_name: "Second",
          run_time_statistics: %Statistics{
            average: 200.0,
            ips: 5_000.0,
            std_dev_ratio: 0.1,
            median: 195.5,
            percentiles: %{99 => 300.1}
          }
        },
        %Scenario{
          job_name: "First",
          run_time_statistics: %Statistics{
            average: 100.0,
            ips: 10_000.0,
            std_dev_ratio: 0.1,
            median: 90.0,
            percentiles: %{99 => 200.1}
          }
        }
      ]

      output =  Enum.join Console.format_scenarios(
                  scenarios,
                  %{
                    comparison:       false,
                    unit_scaling:     :best,
                    extended_statistics: false
                  })

      refute Regex.match? ~r/Comparison/i, output
      refute Regex.match? ~r/^First\s+10 K$/m, output
      refute Regex.match? ~r/^Second\s+5 K\s+- 2.00x slower/, output
    end

    test "adjusts the label width to longest name for comparisons" do
      second_name = String.duplicate("a", 40)
      scenarios = [
        %Scenario{
          job_name: second_name,
          run_time_statistics: %Statistics{
            average: 200.0,
            ips: 5_000.0,
            std_dev_ratio: 0.1,
            median: 195.5,
            percentiles: %{99 => 300.1}
          }
        },
        %Scenario{
          job_name: "First",
          run_time_statistics: %Statistics{
            average: 100.0,
            ips: 10_000.0,
            std_dev_ratio: 0.1,
            median: 90.0,
            percentiles: %{99 => 200.1}
          }
        }
      ]

      expected_width = String.length(second_name)
      [_, _, _, _comp_header, reference, slower] =
        Console.format_scenarios(scenarios, @console_config)

      assert_column_width "First", reference, expected_width
      assert_column_width second_name, slower, expected_width
    end

    test "doesn't create comparisons with only one benchmark run" do
      scenarios = [
        %Scenario{
          job_name: "First",
          run_time_statistics: %Statistics{
            average: 100.0,
            ips: 10_000.0,
            std_dev_ratio: 0.1,
            median: 90.0,
            percentiles: %{99 => 200.1}
          }
        }
      ]

      assert [header, result] = Console.format_scenarios(scenarios, @console_config)
      refute Regex.match? ~r/(Comparison|x slower)/, Enum.join([header, result])
    end

    test "formats small averages, medians, and percentiles more precisely" do
      scenarios = [
        %Scenario{
          job_name: "First",
          run_time_statistics: %Statistics{
            average: 0.15,
            ips: 10_000.0,
            std_dev_ratio: 0.1,
            median: 0.0125,
            percentiles: %{99 => 0.0234}
          }
        }
      ]

      assert [_, result] = Console.format_scenarios(scenarios, @console_config)
      assert Regex.match? ~r/0.150\s?μs/, result
      assert Regex.match? ~r/0.0125\s?μs/, result
      assert Regex.match? ~r/0.0234\s?μs/, result
    end

    test "doesn't output weird 'e' formats" do
      scenarios = [
        %Scenario{
          job_name: "Job",
          run_time_statistics: %Statistics{
            average: 11000.0,
            ips: 12000.0,
            std_dev_ratio: 13000.0,
            median: 140000.0,
            percentiles: %{99 => 200000.1}
          }
        }
      ]

      assert [_, result] = Console.format_scenarios(scenarios, @console_config)

      refute result =~ ~r/\de\d/
      assert result =~ "11 ms"
      assert result =~ "12 K"
      assert result =~ "13000"
      assert result =~ "140 ms"
      assert result =~ "200.00 ms"
    end
  end

  describe ".format" do
    @header_regex ~r/Name.+ips.+average.+deviation.+median.+99th %.*/
    test "with multiple inputs and just one job" do
      scenarios = [
        %Scenario{
          job_name: "Job",
          input_name: "My Arg",
          input: "My Arg",
          run_time_statistics: %Statistics{
            average: 200.0,
            ips: 5_000.0,
            std_dev_ratio: 0.1,
            median: 195.5,
            percentiles: %{99 => 400.1}
          }
        },
        %Scenario{
          job_name: "Job",
          input_name: "Other Arg",
          input: "Other Arg",
          run_time_statistics: %Statistics{
            average: 400.0,
            ips: 2_500.0,
            std_dev_ratio: 0.15,
            median: 395.0,
            percentiles: %{99 => 500.1}
          }
        }
      ]

      [my_arg, other_arg] =
        Console.format(%Suite{scenarios: scenarios, configuration: @config})

      [input_header, header, result] = my_arg
      assert input_header =~ "My Arg"
      assert header =~ @header_regex
      assert result =~ ~r/Job.+5.+200.+10\.00%.+195\.5.+400\.1/

      [input_header_2, header_2, result_2] = other_arg
      assert input_header_2 =~ "Other Arg"
      assert header_2 =~ @header_regex
      assert result_2 =~ ~r/Job.+2\.5.+400.+15\.00%.+395.+500\.1/
    end

    test "with multiple inputs and two jobs" do
      scenarios = [
        %Scenario{
          job_name: "Job",
          input_name: "My Arg",
          input: "My Arg",
          run_time_statistics: %Statistics{
            average: 200.0,
            ips: 5_000.0,
            std_dev_ratio: 0.1,
            median: 195.5,
            percentiles: %{99 => 300.1}
          }
        },
        %Scenario{
          job_name: "Other Job",
          input_name: "My Arg",
          input: "My Arg",
          run_time_statistics: %Statistics{
            average: 100.0,
            ips: 10_000.0,
            std_dev_ratio: 0.3,
            median: 98.0,
            percentiles: %{99 => 200.1}
          }
        },
        %Scenario{
          job_name: "Job",
          input_name: "Other Arg",
          input: "Other Arg",
          run_time_statistics: %Statistics{
            average: 400.0,
            ips: 2_500.0,
            std_dev_ratio: 0.15,
            median: 395.0,
            percentiles: %{99 => 500.1}
          }
        },
        %Scenario{
          job_name: "Other Job",
          input_name: "Other Arg",
          input: "Other Arg",
          run_time_statistics: %Statistics{
            average: 250.0,
            ips: 4_000.0,
            std_dev_ratio: 0.31,
            median: 225.5,
            percentiles: %{99 => 300.1}
          }
        }
      ]

      [my_arg, other_arg] =
        Console.format(%Suite{scenarios: scenarios, configuration: @config})

      [input_header, _header, other_job, job, _comp, ref, slower] = my_arg
      assert input_header =~ "My Arg"
      assert other_job =~ ~r/Other Job.+10.+100.+30\.00%.+98.+200\.1/
      assert job =~ ~r/Job.+5.+200.+10\.00%.+195\.5/
      ref =~ ~r/Other Job/
      slower =~ ~r/Job.+slower/

      [input_header_2, _, other_job_2, job_2, _, ref_2, slower_2] = other_arg
      assert input_header_2 =~ "Other Arg"
      assert other_job_2 =~ ~r/Other Job.+4.+250.+31\.00%.+225\.5.+300\.1/
      assert job_2 =~ ~r/Job.+2\.5.+400.+15\.00%.+395/
      ref_2 =~ ~r/Other Job/
      slower_2 =~ ~r/Job.+slower/
    end

    test "with and without a tag" do
      scenarios = [
        %Scenario{
          job_name: "job",
          input_name: no_input(),
          input: no_input(),
          run_time_statistics: %Statistics{
            average: 200.0,
            ips: 5_000.0,
            std_dev_ratio: 0.1,
            median: 195.5,
            percentiles: %{99 => 300.1}
          }
        },
        %Scenario{
          job_name: "job",
          tag: "improved",
          input_name: no_input(),
          input: no_input(),
          run_time_statistics: %Statistics{
            average: 100.0,
            ips: 10_000.0,
            std_dev_ratio: 0.1,
            median: 90.0,
            percentiles: %{99 => 200.1}
          }
        }
      ]

      [result] = Console.format(%Suite{scenarios: scenarios, configuration: @config})
      [_, _header, job_with_tag, job, _, comparison, _slower] = result

      assert job_with_tag =~ ~r/job \(improved\)\s+10 K/
      assert job          =~ ~r/job\s+5 K/
      assert comparison   =~ ~r/job \(improved\)\s+ 10 K/
    end
  end

  defp assert_column_width(name, string, expected_width) do
    # add 13 characters for the ips column, and an extra space between the columns
    expected_width = expected_width + 14
    n = Regex.escape name
    regex = Regex.compile! "(#{n} +([0-9\.]+( [[:alpha:]]+)?|ips))( |$)"
    assert Regex.match? regex, string
    [column | _] = Regex.run(regex, string, capture: :all_but_first)
    column_width = String.length(column)

    assert expected_width == column_width, """
Expected column width of #{expected_width}, got #{column_width}
line:   #{inspect String.trim(string)}
column: #{inspect column}
"""
  end
end
