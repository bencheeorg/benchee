defmodule Benchee.StatistcsTest do
  use ExUnit.Case, async: true

  alias Benchee.{CollectionData, Configuration, Scenario, Statistics, Suite}
  alias Benchee.Test.FakeProgressPrinter

  doctest Benchee.Statistics, import: true

  @sample_1 [600, 470, 170, 430, 300]
  @sample_2 [17, 15, 23, 7, 9, 13]
  @sample_3 [5]
  @sample_4 [100, 100, 100, 100]
  @sample_5 [5, 10, 15]
  @sample_6 [10, 20]
  describe ".statistics" do
    test "computes the statistics for all jobs correctly" do
      scenarios = [
        %Scenario{
          input: "Input",
          input_name: "Input",
          job_name: "Job 1",
          run_time_data: %CollectionData{samples: @sample_1},
          memory_usage_data: %CollectionData{samples: @sample_3},
          reductions_data: %CollectionData{samples: @sample_5}
        },
        %Scenario{
          input: "Input",
          input_name: "Input",
          job_name: "Job 2",
          run_time_data: %CollectionData{samples: @sample_2},
          memory_usage_data: %CollectionData{samples: @sample_4},
          reductions_data: %CollectionData{samples: @sample_6}
        }
      ]

      suite = %Suite{scenarios: scenarios}
      new_suite = Statistics.statistics(suite, FakeProgressPrinter)

      stats_1 = run_time_stats_for(new_suite, "Job 1", "Input")
      stats_2 = run_time_stats_for(new_suite, "Job 2", "Input")

      stats_3 = stats_for(new_suite, "Job 1", "Input", :memory_usage_data)
      stats_4 = stats_for(new_suite, "Job 2", "Input", :memory_usage_data)

      stats_5 = stats_for(new_suite, "Job 1", "Input", :reductions_data)
      stats_6 = stats_for(new_suite, "Job 2", "Input", :reductions_data)

      sample_1_asserts(stats_1)
      sample_2_asserts(stats_2)
      sample_3_asserts(stats_3)
      sample_4_asserts(stats_4)
      sample_5_asserts(stats_5)
      sample_6_asserts(stats_6)
    end

    test "computes statistics correctly for multiple inputs" do
      scenarios = [
        %Scenario{
          input: "Input 1",
          input_name: "Input 1",
          job_name: "Job 1",
          run_time_data: %CollectionData{samples: @sample_1},
          memory_usage_data: %CollectionData{samples: @sample_1}
        },
        %Scenario{
          input: "Input 1",
          input_name: "Input 1",
          job_name: "Job 2",
          run_time_data: %CollectionData{samples: @sample_2},
          memory_usage_data: %CollectionData{samples: @sample_2}
        },
        %Scenario{
          input: "Input 2",
          input_name: "Input 2",
          job_name: "Job 1",
          run_time_data: %CollectionData{samples: @sample_1},
          memory_usage_data: %CollectionData{samples: @sample_1}
        },
        %Scenario{
          input: "Input 2",
          input_name: "Input 2",
          job_name: "Job 2",
          run_time_data: %CollectionData{samples: @sample_2},
          memory_usage_data: %CollectionData{samples: @sample_2}
        }
      ]

      suite = %Suite{
        scenarios: scenarios,
        configuration: %Benchee.Configuration{
          inputs: %{"Input 1" => "Input 1", "Input 2" => "Input2"}
        }
      }

      new_suite = Statistics.statistics(suite, FakeProgressPrinter)

      stats_1_1 = run_time_stats_for(new_suite, "Job 1", "Input 1")
      stats_1_2 = run_time_stats_for(new_suite, "Job 2", "Input 1")
      stats_2_1 = run_time_stats_for(new_suite, "Job 1", "Input 2")
      stats_2_2 = run_time_stats_for(new_suite, "Job 2", "Input 2")

      sample_1_asserts(stats_1_1)
      sample_2_asserts(stats_1_2)
      sample_1_asserts(stats_2_1)
      sample_2_asserts(stats_2_2)
    end

    test "preserves all other keys in the suite handed to it" do
      suite = %Suite{
        scenarios: [],
        configuration: %Configuration{formatters: []}
      }

      assert %Suite{configuration: %{formatters: []}} =
               Statistics.statistics(suite, FakeProgressPrinter)
    end

    test "calculates percentiles configured by the user" do
      suite = %Suite{
        configuration: %Configuration{
          percentiles: [25, 50, 75]
        },
        scenarios: [
          %Scenario{
            run_time_data: %CollectionData{samples: [1, 2]},
            memory_usage_data: %CollectionData{samples: [1, 2]}
          }
        ]
      }

      %Suite{
        scenarios: [
          %Scenario{
            run_time_data: %CollectionData{
              statistics: %Statistics{
                percentiles: %{
                  25 => _,
                  50 => _,
                  75 => _
                }
              }
            }
          }
        ]
      } = Statistics.statistics(suite, FakeProgressPrinter)
    end

    test "always calculates the 50th percentile, even if not set in the config" do
      suite = %Suite{
        configuration: %Configuration{
          percentiles: [25, 75]
        },
        scenarios: [
          %Scenario{
            run_time_data: %CollectionData{samples: [1, 2]},
            memory_usage_data: %CollectionData{samples: [1, 2]}
          }
        ]
      }

      %Suite{
        scenarios: [
          %Scenario{
            run_time_data: %CollectionData{
              statistics: %Statistics{
                percentiles: %{
                  25 => _,
                  50 => _,
                  75 => _
                }
              }
            }
          }
        ]
      } = Statistics.statistics(suite, FakeProgressPrinter)
    end

    @nothing []
    test "doesn't blow up whenthere are no measurements" do
      scenarios = [
        %Scenario{
          run_time_data: %CollectionData{samples: @nothing},
          memory_usage_data: %CollectionData{samples: @nothing},
          reductions_data: %CollectionData{samples: @nothing}
        }
      ]

      suite = Statistics.statistics(%Suite{scenarios: scenarios}, FakeProgressPrinter)

      [
        %Scenario{
          run_time_data: %CollectionData{statistics: run_time_stats},
          memory_usage_data: %CollectionData{statistics: memory_stats},
          reductions_data: %CollectionData{statistics: reductions_stats}
        }
      ] = suite.scenarios

      assert run_time_stats.sample_size == 0
      assert memory_stats.sample_size == 0
      assert reductions_stats.sample_size == 0

      assert run_time_stats.average == nil
      assert memory_stats.average == nil
      assert reductions_stats.average == nil
    end

    test "lets you know it's benchmarking" do
      Statistics.statistics(%Suite{}, FakeProgressPrinter)

      assert_received :calculating_statistics
    end

    defp run_time_stats_for(suite, job_name, input_name) do
      stats_for(suite, job_name, input_name, :run_time_data)
    end

    defp stats_for(suite, job_name, input_name, access_key) do
      collection_data =
        suite.scenarios
        |> Enum.find(fn scenario ->
          scenario.job_name == job_name && scenario.input_name == input_name
        end)
        |> Map.get(access_key)

      collection_data.statistics
    end

    defp sample_1_asserts(stats, opts \\ []) do
      assert stats.average == 394.0
      assert_in_delta stats.std_dev, 164.71, 0.01
      assert_in_delta stats.std_dev_ratio, 0.41, 0.01
      if Access.get(opts, :show_ips), do: assert_in_delta(stats.ips, 2_538_071, 1)
      assert stats.median == 430.0
      assert stats.minimum == 170
      assert stats.maximum == 600
      assert stats.sample_size == 5
      assert stats.mode == nil
    end

    defp sample_2_asserts(stats, opts \\ []) do
      assert stats.average == 14.0
      assert_in_delta stats.std_dev, 5.76, 0.01
      assert_in_delta stats.std_dev_ratio, 0.41, 0.01
      if Access.get(opts, :show_ips), do: assert_in_delta(stats.ips, 71_428_571, 1)
      assert stats.median == 14.0
      assert stats.minimum == 7
      assert stats.maximum == 23
      assert stats.sample_size == 6
      assert stats.mode == nil
    end

    defp sample_3_asserts(stats) do
      assert stats.average == 5.0
      assert stats.std_dev == 0.0
      assert stats.std_dev_ratio == 0.0
      assert stats.median == 5.0
      assert stats.minimum == 5
      assert stats.maximum == 5
      assert stats.sample_size == 1
      assert stats.mode == nil
    end

    defp sample_4_asserts(stats) do
      assert stats.average == 100.0
      assert stats.std_dev == 0.0
      assert stats.std_dev_ratio == 0.0
      assert stats.median == 100.0
      assert stats.minimum == 100
      assert stats.maximum == 100
      assert stats.sample_size == 4
      assert stats.mode == 100
    end

    defp sample_5_asserts(stats) do
      assert stats.average == 10.0
      assert stats.std_dev == 5.0
      assert stats.std_dev_ratio == 0.5
      assert stats.median == 10.0
      assert stats.minimum == 5
      assert stats.maximum == 15
      assert stats.sample_size == 3
      assert stats.mode == nil
    end

    defp sample_6_asserts(stats) do
      assert stats.average == 15.0
      assert_in_delta stats.std_dev, 7.07, 0.01
      assert_in_delta stats.std_dev_ratio, 0.47, 0.01
      assert stats.median == 15.0
      assert stats.minimum == 10
      assert stats.maximum == 20
      assert stats.sample_size == 2
      assert stats.mode == nil
    end
  end
end
