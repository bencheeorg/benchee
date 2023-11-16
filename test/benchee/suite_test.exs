defmodule Benchee.SuiteTest do
  use ExUnit.Case, async: true

  import DeepMerge

  alias Benchee.Suite
  alias Benchee.System

  @system %System{
    elixir: "1.4.0",
    erlang: "19.2",
    jit_enabled?: false,
    num_cores: "4",
    os: "Super Duper",
    available_memory: "8 Trillion",
    cpu_speed: "light speed"
  }
  @empty_suite %Suite{
    system: @system,
    scenarios: []
  }

  describe "deep_merge resolver" do
    test "merges with another Suite rejecting nil values in the override" do
      override = %Suite{
        system: %{elixir: "1.5.0-dev"},
        scenarios: nil
      }

      result = deep_merge(@empty_suite, override)

      assert %Suite{
               system: %{elixir: "1.5.0-dev", erlang: "19.2"},
               scenarios: []
             } = result
    end

    test "merges with a map" do
      override = %{
        system: %{elixir: "1.5.0-dev"}
      }

      result = deep_merge(@empty_suite, override)

      assert %Suite{
               system: %{elixir: "1.5.0-dev", erlang: "19.2"}
             } = result
    end

    test "raises when anything else is tried" do
      assert_raise FunctionClauseError, fn ->
        deep_merge(@empty_suite, "lol this doesn't fit")
      end
    end
  end

  if Code.ensure_loaded?(Table.Reader) do
    describe "Table.Reader protocol" do
      @suite_with_data %Suite{
        system: @system,
        configuration: %Benchee.Configuration{
          percentiles: [50, 99]
        },
        scenarios: [
          %Benchee.Scenario{
            job_name: "Test 1",
            memory_usage_data: %Benchee.CollectionData{
              samples: [1_792, 1_792, 1_792],
              statistics: %Benchee.Statistics{
                absolute_difference: nil,
                average: 1_792.0,
                ips: nil,
                maximum: 1_792,
                median: 1_792.0,
                minimum: 1_792,
                mode: 1_792,
                percentiles: %{50 => 1_792.0, 99 => 1_792.0},
                relative_less: nil,
                relative_more: nil,
                sample_size: 3,
                std_dev: +0.0,
                std_dev_ips: nil,
                std_dev_ratio: +0.0
              }
            },
            name: "Test 1",
            reductions_data: %Benchee.CollectionData{
              samples: [],
              statistics: %Benchee.Statistics{}
            },
            run_time_data: %Benchee.CollectionData{
              samples: [21_580, 2_986, 11_502],
              statistics: %Benchee.Statistics{
                absolute_difference: nil,
                average: 2_854.02659820102,
                ips: 350_382.1585371105,
                maximum: 3_741_076,
                median: 2_164.0,
                minimum: 2_063,
                mode: 2_124,
                percentiles: %{50 => 2_164.0, 99 => 5881.0},
                relative_less: nil,
                relative_more: nil,
                sample_size: 3,
                std_dev: 13_106.875011228927,
                std_dev_ips: 1_609_100.3359973046,
                std_dev_ratio: 4.592415158110506
              }
            }
          },
          %Benchee.Scenario{
            job_name: "Test 2",
            memory_usage_data: %Benchee.CollectionData{
              samples: [1_792, 1_792, 1_792],
              statistics: %Benchee.Statistics{
                absolute_difference: nil,
                average: 1_792.0,
                ips: nil,
                maximum: 1_792,
                median: 1_792.0,
                minimum: 1_792,
                mode: 1_792,
                percentiles: %{50 => 1_792.0, 99 => 1_792.0},
                relative_less: nil,
                relative_more: nil,
                sample_size: 3,
                std_dev: +0.0,
                std_dev_ips: nil,
                std_dev_ratio: +0.0
              }
            },
            name: "Test 2",
            reductions_data: %Benchee.CollectionData{
              samples: [],
              statistics: %Benchee.Statistics{}
            },
            run_time_data: %Benchee.CollectionData{
              samples: [21_580, 2_986, 11_502],
              statistics: %Benchee.Statistics{
                absolute_difference: nil,
                average: 2_854.02659820102,
                ips: 350_382.1585371105,
                maximum: 3_741_076,
                median: 2_164.0,
                minimum: 2_063,
                mode: 2_124,
                percentiles: %{50 => 2_164.0, 99 => 5881.0},
                relative_less: nil,
                relative_more: nil,
                sample_size: 3,
                std_dev: 13_106.875011228927,
                std_dev_ips: 1_609_100.3359973046,
                std_dev_ratio: 4.592415158110506
              }
            }
          }
        ]
      }

      @suite_with_reductions %Suite{
        system: @system,
        configuration: %Benchee.Configuration{
          percentiles: [50, 99]
        },
        scenarios: [
          %Benchee.Scenario{
            job_name: "Test 1",
            memory_usage_data: %Benchee.CollectionData{
              samples: [1_792, 1_792, 1_792],
              statistics: %Benchee.Statistics{
                absolute_difference: nil,
                average: 1_792.0,
                ips: nil,
                maximum: 1_792,
                median: 1_792.0,
                minimum: 1_792,
                mode: 1_792,
                percentiles: %{50 => 1_792.0, 99 => 1_792.0},
                relative_less: nil,
                relative_more: nil,
                sample_size: 3,
                std_dev: +0.0,
                std_dev_ips: nil,
                std_dev_ratio: +0.0
              }
            },
            reductions_data: %Benchee.CollectionData{
              samples: [55, 55],
              statistics: %Benchee.Statistics{
                average: 55.0,
                ips: nil,
                maximum: 55,
                median: 55.0,
                minimum: 55,
                mode: 55,
                percentiles: %{50 => 55.0, 99 => 55.0},
                relative_less: nil,
                relative_more: nil,
                sample_size: 2,
                std_dev: +0.0,
                std_dev_ips: nil,
                std_dev_ratio: +0.0
              }
            },
            run_time_data: %Benchee.CollectionData{
              samples: [21_580, 2_986, 11_502],
              statistics: %Benchee.Statistics{
                absolute_difference: nil,
                average: 2_854.02659820102,
                ips: 350_382.1585371105,
                maximum: 3_741_076,
                median: 2_164.0,
                minimum: 2_063,
                mode: 2_124,
                percentiles: %{50 => 2_164.0, 99 => 5881.0},
                relative_less: nil,
                relative_more: nil,
                sample_size: 3,
                std_dev: 13_106.875011228927,
                std_dev_ips: 1_609_100.3359973046,
                std_dev_ratio: 4.592415158110506
              }
            }
          }
        ]
      }

      test "should return a table when no scenarios are in the suite" do
        table_results = Table.Reader.init(@empty_suite)

        assert {:rows,
                %{
                  columns: [
                    "job_name"
                  ],
                  count: 0
                }, []} = table_results
      end

      test "should return a table with data when multiple scenarios are in the suite" do
        table_results = Table.Reader.init(@suite_with_data)

        assert {:rows,
                %{
                  columns: [
                    "job_name",
                    "run_time_samples",
                    "run_time_ips",
                    "run_time_average",
                    "run_time_std_dev",
                    "run_time_median",
                    "run_time_minimum",
                    "run_time_maximum",
                    "run_time_mode",
                    "run_time_sample_size",
                    "run_time_p_50",
                    "run_time_p_99",
                    "memory_samples",
                    "memory_average",
                    "memory_std_dev",
                    "memory_median",
                    "memory_minimum",
                    "memory_maximum",
                    "memory_mode",
                    "memory_sample_size",
                    "memory_p_50",
                    "memory_p_99"
                  ],
                  count: 2
                },
                [
                  [
                    "Test 1",
                    [21_580, 2_986, 11_502],
                    350_382.1585371105,
                    2_854.02659820102,
                    13_106.875011228927,
                    2_164.0,
                    2_063,
                    3_741_076,
                    2_124,
                    3,
                    2_164.0,
                    5881.0,
                    [1_792, 1_792, 1_792],
                    1_792.0,
                    +0.0,
                    1_792.0,
                    1_792,
                    1_792,
                    1_792,
                    3,
                    1_792.0,
                    1_792.0
                  ],
                  [
                    "Test 2",
                    [21_580, 2_986, 11_502],
                    350_382.1585371105,
                    2_854.02659820102,
                    13_106.875011228927,
                    2_164.0,
                    2_063,
                    3_741_076,
                    2_124,
                    3,
                    2_164.0,
                    5881.0,
                    [1_792, 1_792, 1_792],
                    1_792.0,
                    +0.0,
                    1_792.0,
                    1_792,
                    1_792,
                    1_792,
                    3,
                    1_792.0,
                    1_792.0
                  ]
                ]} = table_results
      end

      test "should return a table with all data if every measurment has values" do
        table_results = Table.Reader.init(@suite_with_reductions)

        assert {:rows,
                %{
                  columns: [
                    "job_name",
                    "run_time_samples",
                    "run_time_ips",
                    "run_time_average",
                    "run_time_std_dev",
                    "run_time_median",
                    "run_time_minimum",
                    "run_time_maximum",
                    "run_time_mode",
                    "run_time_sample_size",
                    "run_time_p_50",
                    "run_time_p_99",
                    "memory_samples",
                    "memory_average",
                    "memory_std_dev",
                    "memory_median",
                    "memory_minimum",
                    "memory_maximum",
                    "memory_mode",
                    "memory_sample_size",
                    "memory_p_50",
                    "memory_p_99",
                    "reductions_samples",
                    "reductions_average",
                    "reductions_std_dev",
                    "reductions_median",
                    "reductions_minimum",
                    "reductions_maximum",
                    "reductions_mode",
                    "reductions_sample_size",
                    "reductions_p_50",
                    "reductions_p_99"
                  ],
                  count: 1
                },
                [
                  [
                    "Test 1",
                    [21_580, 2_986, 11_502],
                    350_382.1585371105,
                    2_854.02659820102,
                    13_106.875011228927,
                    2_164.0,
                    2_063,
                    3_741_076,
                    2_124,
                    3,
                    2_164.0,
                    5881.0,
                    [1_792, 1_792, 1_792],
                    1_792.0,
                    +0.0,
                    1_792.0,
                    1_792,
                    1_792,
                    1_792,
                    3,
                    1_792.0,
                    1_792.0,
                    [55, 55],
                    55.0,
                    +0.0,
                    55.0,
                    55,
                    55,
                    55,
                    2,
                    55.0,
                    55.0
                  ]
                ]} = table_results
      end
    end
  end
end
