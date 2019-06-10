defmodule Benchee.Formatters.Console.ReductionsTest do
  use ExUnit.Case, async: true
  doctest Benchee.Formatters.Console.Reductions

  alias Benchee.{CollectionData, Formatters.Console.Reductions, Scenario, Statistics}

  @console_config %{
    comparison: true,
    unit_scaling: :best,
    extended_statistics: false
  }

  describe ".format_scenarios" do
    test "adjusts the label width to longest name" do
      scenarios = [
        %Scenario{
          name: "First",
          reductions_data: %CollectionData{
            statistics: %Statistics{
              average: 200.0,
              ips: 5_000.0,
              std_dev_ratio: 0.1,
              median: 195.5,
              percentiles: %{99 => 300.1},
              sample_size: 10
            }
          },
          run_time_data: %CollectionData{statistics: %Statistics{average: 100.0, ips: 1_000.0}}
        },
        %Scenario{
          name: "Second",
          reductions_data: %CollectionData{
            statistics: %Statistics{
              average: 400.0,
              ips: 2_500.0,
              std_dev_ratio: 0.1,
              median: 375.0,
              percentiles: %{99 => 400.1},
              sample_size: 10,
              relative_more: 2.0,
              absolute_difference: 200.0
            }
          },
          run_time_data: %CollectionData{statistics: %Statistics{average: 100.0, ips: 1_000.0}}
        }
      ]

      expected_width = String.length("Second")

      [_reductions_header, header, result_1, result_2 | _dont_care] =
        Reductions.format_scenarios(scenarios, @console_config)

      assert_column_width("Name", header, expected_width)
      assert_column_width("First", result_1, expected_width)
      assert_column_width("Second", result_2, expected_width)

      third_length = 40
      third_name = String.duplicate("a", third_length)

      long_scenario = %Scenario{
        name: third_name,
        reductions_data: %CollectionData{
          statistics: %Statistics{
            average: 400.1,
            ips: 2_500.0,
            std_dev_ratio: 0.1,
            median: 375.0,
            percentiles: %{99 => 500.1},
            sample_size: 10,
            relative_more: 2.005,
            absolute_difference: 200.1
          }
        },
        run_time_data: %CollectionData{statistics: %Statistics{average: 100.0, ips: 1_000.0}}
      }

      longer_scenarios = scenarios ++ [long_scenario]

      # Include extra long name, expect width of 40 characters
      [_reductions_header, header, result_1, result_2, result_3 | _dont_care] =
        Reductions.format_scenarios(longer_scenarios, @console_config)

      assert_column_width("Name", header, third_length)
      assert_column_width("First", result_1, third_length)
      assert_column_width("Second", result_2, third_length)
      assert_column_width(third_name, result_3, third_length)
    end

    test "can omit the comparisons" do
      scenarios = [
        %Scenario{
          name: "Second",
          reductions_data: %CollectionData{
            statistics: %Statistics{
              average: 200.0,
              ips: 5_000.0,
              std_dev_ratio: 0.1,
              median: 195.5,
              percentiles: %{99 => 300.1},
              sample_size: 10
            }
          },
          run_time_data: %CollectionData{statistics: %Statistics{average: 100.0, ips: 1_000.0}}
        },
        %Scenario{
          name: "First",
          reductions_data: %CollectionData{
            statistics: %Statistics{
              average: 100.0,
              ips: 10_000.0,
              std_dev_ratio: 0.1,
              median: 90.0,
              percentiles: %{99 => 200.1},
              sample_size: 10
            }
          },
          run_time_data: %CollectionData{statistics: %Statistics{average: 100.0, ips: 1_000.0}}
        }
      ]

      output =
        Enum.join(
          Reductions.format_scenarios(scenarios, %{
            comparison: false,
            unit_scaling: :best,
            extended_statistics: false
          })
        )

      refute output =~ ~r/Comparison/i
      refute output =~ ~r/^First\s+90$/m
    end

    test "creates comparisons" do
      scenarios = [
        %Scenario{
          name: "First",
          reductions_data: %CollectionData{
            statistics: %Statistics{
              average: 90.0,
              ips: 10_000.0,
              std_dev_ratio: 0.1,
              median: 90.0,
              percentiles: %{99 => 500.1},
              sample_size: 10
            }
          },
          run_time_data: %CollectionData{statistics: %Statistics{average: 100.0, ips: 1_000.0}}
        },
        %Scenario{
          name: "Second",
          reductions_data: %CollectionData{
            statistics: %Statistics{
              average: 195.5,
              ips: 5_000.0,
              std_dev_ratio: 0.1,
              median: 195.5,
              percentiles: %{99 => 500.1},
              sample_size: 10,
              relative_more: 2.17,
              absolute_difference: 105.5
            }
          },
          run_time_data: %CollectionData{statistics: %Statistics{average: 100.0, ips: 1_000.0}}
        }
      ]

      output = Reductions.format_scenarios(scenarios, @console_config)
      [_, _, _, _, comp_header, reference, slower] = output

      assert comp_header =~ ~r/Comparison/
      assert reference =~ ~r/^First\s+90$/m
      assert slower =~ ~r/^Second\s+195.50\s+- 2.17x reduction count \+105\.50$/m
    end

    test "adjusts the label width to longest name for comparisons" do
      second_name = String.duplicate("a", 40)

      scenarios = [
        %Scenario{
          name: "First",
          reductions_data: %CollectionData{
            statistics: %Statistics{
              average: 100.0,
              ips: 10_000.0,
              std_dev_ratio: 0.1,
              median: 90.0,
              percentiles: %{99 => 200.1},
              sample_size: 10
            }
          },
          run_time_data: %CollectionData{statistics: %Statistics{average: 100.0, ips: 1_000.0}}
        },
        %Scenario{
          name: second_name,
          reductions_data: %CollectionData{
            statistics: %Statistics{
              average: 200.0,
              ips: 5_000.0,
              std_dev_ratio: 0.1,
              median: 195.5,
              percentiles: %{99 => 300.1},
              sample_size: 10,
              relative_more: 2.0,
              absolute_difference: 100.0
            }
          },
          run_time_data: %CollectionData{statistics: %Statistics{average: 100.0, ips: 1_000.0}}
        }
      ]

      expected_width = String.length(second_name)

      [_, _, _, _, _comp_header, reference, slower] =
        Reductions.format_scenarios(scenarios, @console_config)

      assert_column_width("First", reference, expected_width)
      assert_column_width(second_name, slower, expected_width)
    end

    test "doesn't display statistics if all deviations are 0.0" do
      scenarios = [
        %Scenario{
          name: "First",
          reductions_data: %CollectionData{
            statistics: %Statistics{
              average: 100.0,
              std_dev: 0.0,
              std_dev_ratio: 0.0,
              median: 100.0,
              percentiles: %{99 => 100.0},
              sample_size: 10
            }
          },
          run_time_data: %CollectionData{statistics: %Statistics{average: 100.0, ips: 1_000.0}}
        },
        %Scenario{
          name: "Second",
          reductions_data: %CollectionData{
            statistics: %Statistics{
              average: 200.0,
              std_dev: 0.0,
              std_dev_ratio: 0.0,
              median: 200.0,
              percentiles: %{99 => 200.0},
              sample_size: 10,
              relative_more: 2.0,
              absolute_difference: 100.0
            }
          },
          run_time_data: %CollectionData{statistics: %Statistics{average: 100.0, ips: 1_000.0}}
        }
      ]

      output =
        Enum.join(
          Reductions.format_scenarios(scenarios, %{
            comparison: true,
            unit_scaling: :best,
            extended_statistics: false
          })
        )

      refute Regex.match?(~r/Comparison/i, output)
      refute Regex.match?(~r/average/i, output)
    end

    test "doesn't create comparisons with only one benchmark run" do
      scenarios = [
        %Scenario{
          name: "First",
          reductions_data: %CollectionData{
            statistics: %Statistics{
              average: 100.0,
              ips: 10_000.0,
              std_dev_ratio: 0.1,
              median: 90.0,
              percentiles: %{99 => 200.1},
              sample_size: 10
            }
          },
          run_time_data: %CollectionData{statistics: %Statistics{average: 100.0, ips: 1_000.0}}
        }
      ]

      assert [_, header, result] = Reductions.format_scenarios(scenarios, @console_config)
      refute Regex.match?(~r/(Comparison|x reduction)/, Enum.join([header, result]))
    end

    test "displays extended statistics" do
      scenarios = [
        %Scenario{
          name: "First job",
          reductions_data: %CollectionData{
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
          run_time_data: %CollectionData{statistics: %Statistics{average: 100.0, ips: 1_000.0}}
        }
      ]

      params = %{
        comparison: true,
        unit_scaling: :best,
        extended_statistics: true
      }

      output = Reductions.format_scenarios(scenarios, params)
      [_reductions_title, _header1, _result1, title, header2, result2] = output

      assert title =~ "Extended statistics: "
      assert header2 =~ "minimum"
      assert header2 =~ "maximum"
      assert header2 =~ "sample size"
      assert header2 =~ "mode"
      assert result2 =~ "First job"
      assert result2 =~ "111.10"
      assert result2 =~ "333.30"
      assert result2 =~ "50 K"
      assert result2 =~ "201.20"
    end

    test "it doesn't blow up if some of the values have no statistics (yes that happened)" do
      scenarios = [
        %Scenario{
          name: "First",
          reductions_data: %CollectionData{
            statistics: %Statistics{
              average: 100.0,
              std_dev: 0.0,
              std_dev_ratio: 0.0,
              median: 100.0,
              percentiles: %{99 => 100.0},
              sample_size: 10
            }
          },
          run_time_data: %CollectionData{statistics: %Statistics{}}
        },
        %Scenario{
          name: "Second",
          reductions_data: %CollectionData{statistics: %Statistics{}},
          run_time_data: %CollectionData{statistics: %Statistics{}}
        }
      ]

      output =
        Enum.join(
          Reductions.format_scenarios(scenarios, %{
            comparison: true,
            unit_scaling: :best,
            extended_statistics: false
          })
        )

      assert output =~ "First"
      assert output =~ ~r/Second.+N\/A/i
      assert output =~ "N/A"
      assert output =~ "WARNING"
      assert output =~ "report"
    end

    test "doesn't display extended statistics if extended_statistics isn't specified" do
      scenarios = [
        %Scenario{
          name: "First job",
          reductions_data: %CollectionData{
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
          run_time_data: %CollectionData{statistics: %Statistics{average: 100.0, ips: 1_000.0}}
        }
      ]

      params = %{
        unit_scaling: :best
      }

      output = scenarios |> Reductions.format_scenarios(params) |> Enum.join("")

      refute output =~ "Extended statistics: "
      refute output =~ "minimum"
      refute output =~ "maximum"
      refute output =~ "sample size"
      refute output =~ "mode"
      refute output =~ "111.10"
      refute output =~ "333.30"
      refute output =~ "50 K"
      refute output =~ "201.20"
    end

    test "does nothing when there's no statistics to format" do
      scenarios = [
        %Scenario{reductions_data: %CollectionData{statistics: %Statistics{sample_size: 0}}}
      ]

      assert [] = Reductions.format_scenarios(scenarios, %{})
    end

    test "it doesn't blow up if some come back with a median of 0.0" do
      scenarios = [
        %Scenario{
          name: "First",
          reductions_data: %CollectionData{
            statistics: %Statistics{
              average: 0.0,
              median: 0.0,
              sample_size: 10,
              percentiles: %{99 => 0.0},
              std_dev: 0.0,
              std_dev_ratio: 0.0
            }
          },
          run_time_data: %CollectionData{statistics: %Statistics{}}
        },
        %Scenario{
          name: "Second",
          reductions_data: %CollectionData{
            statistics: %Statistics{
              average: 100.0,
              median: 100.0,
              sample_size: 5,
              percentiles: %{99 => 100.0},
              std_dev: 5.0,
              std_dev_ratio: 0.10,
              relative_more: :infinity,
              absolute_difference: 100.0
            }
          },
          run_time_data: %CollectionData{statistics: %Statistics{}}
        }
      ]

      output =
        Enum.join(
          Reductions.format_scenarios(scenarios, %{
            comparison: true,
            unit_scaling: :best,
            extended_statistics: false
          })
        )

      assert output =~ "First"
      assert output =~ "Second"
      assert output =~ "∞ x reduction count"
    end

    test "it doesn't blow up if some come back with a median et. al. of nil" do
      scenarios = [
        %Scenario{
          name: "First",
          reductions_data: %CollectionData{statistics: %Statistics{}},
          run_time_data: %CollectionData{statistics: %Statistics{}}
        },
        %Scenario{
          name: "Second",
          reductions_data: %CollectionData{
            statistics: %Statistics{
              average: 100.0,
              median: 100.0,
              sample_size: 5,
              percentiles: %{99 => 100.0},
              std_dev: 5.0,
              std_dev_ratio: 0.10
            }
          },
          run_time_data: %CollectionData{statistics: %Statistics{}}
        }
      ]

      output =
        Enum.join(
          Reductions.format_scenarios(scenarios, %{
            comparison: true,
            unit_scaling: :best,
            extended_statistics: false
          })
        )

      assert output =~ "First"
      assert output =~ "Second"
      refute output =~ "x reduction count"
    end
  end

  defp assert_column_width(name, string, expected_width) do
    expected_width = expected_width + 16
    n = Regex.escape(name)
    regex = Regex.compile!("(#{n} +([0-9\.]+( [[:alpha:]]+)?|average))( |$)")
    [column | _] = Regex.run(regex, string, capture: :all_but_first)
    column_width = String.length(column)

    assert expected_width == column_width, """
    Expected column width of #{expected_width}, got #{column_width}
    line:   #{inspect(String.trim(string))}
    column: #{inspect(column)}
    """
  end
end
