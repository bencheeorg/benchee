defmodule Benchee.Formatters.Console.RunTimeTest do
  use ExUnit.Case, async: true
  doctest Benchee.Formatters.Console.RunTime

  alias Benchee.{Benchmark.Scenario, Formatters.Console.RunTime, Statistics}

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

  describe ".format_scenarios" do
    test "displays extended statistics" do
      scenarios = [
        %Scenario{
          name: "First job",
          run_time_data: %{
            statistics: %Statistics{
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
          },
          memory_usage_data: %{statistics: %Statistics{}}
        }
      ]

      [_header1, _result1, header1, header2, result2] =
        RunTime.format_scenarios(scenarios, @console_config_extended_params)

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
          name: "First job",
          run_time_data: %{
            statistics: %Statistics{
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
          },
          memory_usage_data: %{statistics: %Statistics{}}
        }
      ]

      [_header1, _result1, _header2, _header3, result2] =
        RunTime.format_scenarios(scenarios, @console_config_extended_params)

      assert result2 =~ ~r/201.20 ns/
      assert result2 =~ ~r/205.55 ns/
    end

    test "displays N/A when no mode exists" do
      scenarios = [
        %Scenario{
          name: "First job",
          run_time_data: %{
            statistics: %Statistics{
              average: 200.0,
              ips: 5_000.0,
              std_dev_ratio: 0.1,
              median: 195.5,
              percentiles: %{99 => 300.1},
              minimum: 111.1,
              maximum: 333.3,
              sample_size: 50_000
            }
          },
          memory_usage_data: %{statistics: %Statistics{}}
        }
      ]

      [_header1, _result1, _header2, _header3, result2] =
        RunTime.format_scenarios(scenarios, @console_config_extended_params)

      assert result2 =~ ~r/None/
    end

    test "adjusts the label width to longest name" do
      scenarios = [
        %Scenario{
          name: "First",
          run_time_data: %{
            statistics: %Statistics{
              average: 200.0,
              ips: 5_000.0,
              std_dev_ratio: 0.1,
              median: 195.5,
              percentiles: %{99 => 300.1},
              sample_size: 200
            }
          },
          memory_usage_data: %{statistics: %Statistics{}}
        },
        %Scenario{
          name: "Second",
          run_time_data: %{
            statistics: %Statistics{
              average: 400.0,
              ips: 2_500.0,
              std_dev_ratio: 0.1,
              median: 375.0,
              percentiles: %{99 => 400.1},
              sample_size: 300
            }
          },
          memory_usage_data: %{statistics: %Statistics{}}
        }
      ]

      expected_width = String.length("Second")

      [header, result_1, result_2 | _dont_care] =
        RunTime.format_scenarios(scenarios, @console_config)

      assert_column_width("Name", header, expected_width)
      assert_column_width("First", result_1, expected_width)
      assert_column_width("Second", result_2, expected_width)

      third_length = 40
      third_name = String.duplicate("a", third_length)

      long_scenario = %Scenario{
        name: third_name,
        run_time_data: %{
          statistics: %Statistics{
            average: 400.1,
            ips: 2_500.0,
            std_dev_ratio: 0.1,
            median: 375.0,
            percentiles: %{99 => 500.1},
            sample_size: 200
          }
        },
        memory_usage_data: %{statistics: %Statistics{}}
      }

      longer_scenarios = scenarios ++ [long_scenario]

      # Include extra long name, expect width of 40 characters
      [header, result_1, result_2, result_3 | _dont_care] =
        RunTime.format_scenarios(longer_scenarios, @console_config)

      assert_column_width("Name", header, third_length)
      assert_column_width("First", result_1, third_length)
      assert_column_width("Second", result_2, third_length)
      assert_column_width(third_name, result_3, third_length)
    end

    test "creates comparisons" do
      scenarios = [
        %Scenario{
          name: "First",
          run_time_data: %{
            statistics: %Statistics{
              average: 100.0,
              ips: 10_000.0,
              std_dev_ratio: 0.1,
              median: 90.0,
              percentiles: %{99 => 500.1},
              sample_size: 400
            }
          },
          memory_usage_data: %{statistics: %Statistics{}}
        },
        %Scenario{
          name: "Second",
          run_time_data: %{
            statistics: %Statistics{
              average: 200.0,
              ips: 5_000.0,
              std_dev_ratio: 0.1,
              median: 195.5,
              percentiles: %{99 => 500.1},
              sample_size: 200
            }
          },
          memory_usage_data: %{statistics: %Statistics{}}
        }
      ]

      [_, _, _, comp_header, reference, slower] =
        RunTime.format_scenarios(scenarios, @console_config)

      assert Regex.match?(~r/Comparison/, comp_header)
      assert Regex.match?(~r/^First\s+10 K$/m, reference)
      assert Regex.match?(~r/^Second\s+5 K\s+- 2.00x slower/, slower)
    end

    test "can omit the comparisons" do
      scenarios = [
        %Scenario{
          name: "Second",
          run_time_data: %{
            statistics: %Statistics{
              average: 200.0,
              ips: 5_000.0,
              std_dev_ratio: 0.1,
              median: 195.5,
              percentiles: %{99 => 300.1},
              sample_size: 200
            }
          },
          memory_usage_data: %{statistics: %Statistics{}}
        },
        %Scenario{
          name: "First",
          run_time_data: %{
            statistics: %Statistics{
              average: 100.0,
              ips: 10_000.0,
              std_dev_ratio: 0.1,
              median: 90.0,
              percentiles: %{99 => 200.1}
            }
          },
          memory_usage_data: %{statistics: %Statistics{}}
        }
      ]

      output =
        Enum.join(
          RunTime.format_scenarios(scenarios, %{
            comparison: false,
            unit_scaling: :best,
            extended_statistics: false
          })
        )

      refute Regex.match?(~r/Comparison/i, output)
      refute Regex.match?(~r/^First\s+10 K$/m, output)
      refute Regex.match?(~r/^Second\s+5 K\s+- 2.00x slower/, output)
    end

    test "adjusts the label width to longest name for comparisons" do
      second_name = String.duplicate("a", 40)

      scenarios = [
        %Scenario{
          name: "First",
          run_time_data: %{
            statistics: %Statistics{
              average: 100.0,
              ips: 10_000.0,
              std_dev_ratio: 0.1,
              median: 90.0,
              percentiles: %{99 => 200.1},
              sample_size: 200
            }
          },
          memory_usage_data: %{statistics: %Statistics{}}
        },
        %Scenario{
          name: second_name,
          run_time_data: %{
            statistics: %Statistics{
              average: 200.0,
              ips: 5_000.0,
              std_dev_ratio: 0.1,
              median: 195.5,
              percentiles: %{99 => 300.1},
              sample_size: 200
            }
          },
          memory_usage_data: %{statistics: %Statistics{}}
        }
      ]

      expected_width = String.length(second_name)

      [_, _, _, _comp_header, reference, slower] =
        RunTime.format_scenarios(scenarios, @console_config)

      assert_column_width("First", reference, expected_width)
      assert_column_width(second_name, slower, expected_width)
    end

    test "doesn't create comparisons with only one benchmark run" do
      scenarios = [
        %Scenario{
          name: "First",
          run_time_data: %{
            statistics: %Statistics{
              average: 100.0,
              ips: 10_000.0,
              std_dev_ratio: 0.1,
              median: 90.0,
              percentiles: %{99 => 200.1},
              sample_size: 200
            }
          },
          memory_usage_data: %{statistics: %Statistics{}}
        }
      ]

      assert [header, result] = RunTime.format_scenarios(scenarios, @console_config)
      refute Regex.match?(~r/(Comparison|x slower)/, Enum.join([header, result]))
    end

    test "formats small averages, medians, and percentiles more precisely" do
      scenarios = [
        %Scenario{
          name: "First",
          run_time_data: %{
            statistics: %Statistics{
              average: 0.15,
              ips: 10_000.0,
              std_dev_ratio: 0.1,
              median: 0.0125,
              percentiles: %{99 => 0.0234},
              sample_size: 200
            }
          },
          memory_usage_data: %{statistics: %Statistics{}}
        }
      ]

      assert [_, result] = RunTime.format_scenarios(scenarios, @console_config)
      assert Regex.match?(~r/0.150\s?ns/, result)
      assert Regex.match?(~r/0.0125\s?ns/, result)
      assert Regex.match?(~r/0.0234\s?ns/, result)
    end

    test "doesn't output weird 'e' formats" do
      scenarios = [
        %Scenario{
          name: "Job",
          run_time_data: %{
            statistics: %Statistics{
              average: 11_000_000.0,
              ips: 12_000.0,
              std_dev_ratio: 13_000.0,
              median: 140_000_000.0,
              percentiles: %{99 => 200_000_000.1},
              sample_size: 200
            }
          },
          memory_usage_data: %{statistics: %Statistics{}}
        }
      ]

      assert [_, result] = RunTime.format_scenarios(scenarios, @console_config)

      refute result =~ ~r/\de\d/
      assert result =~ "11 ms"
      assert result =~ "12 K"
      assert result =~ "13000"
      assert result =~ "140 ms"
      assert result =~ "200.00 ms"
    end

    test "does nothing when there's no statistics to format" do
      scenarios = [%Scenario{run_time_data: %{statistics: %Statistics{sample_size: 0}}}]

      assert [] = RunTime.format_scenarios(scenarios, %{})
    end
  end

  defp assert_column_width(name, string, expected_width) do
    # add 13 characters for the ips column, and an extra space between the columns
    expected_width = expected_width + 14
    n = Regex.escape(name)
    regex = Regex.compile!("(#{n} +([0-9\.]+( [[:alpha:]]+)?|ips))( |$)")
    assert Regex.match?(regex, string)
    [column | _] = Regex.run(regex, string, capture: :all_but_first)
    column_width = String.length(column)

    assert expected_width == column_width, """
    Expected column width of #{expected_width}, got #{column_width}
    line:   #{inspect(String.trim(string))}
    column: #{inspect(column)}
    """
  end
end
