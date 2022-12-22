defmodule Benchee.SuiteTest do
  use ExUnit.Case, async: true

  alias Benchee.Suite
  import DeepMerge

  @empty_suite %Suite{
    system: %{elixir: "1.4.2", erlang: "19.2"},
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

  describe "Table.Reader protocol" do
    @suite_with_data %Suite{
      system: %{elixir: "1.4.2", erlang: "19.2"},
      configuration: %Benchee.Configuration{
        percentiles: [50, 99]
      },
      scenarios: [
        %Benchee.Scenario{
          job_name: "Test 1",
          memory_usage_data: %Benchee.CollectionData{
            samples: [1792, 1792, 1792],
            statistics: %Benchee.Statistics{
              absolute_difference: nil,
              average: 1792.0,
              ips: nil,
              maximum: 1792,
              median: 1792.0,
              minimum: 1792,
              mode: 1792,
              percentiles: %{50 => 1792.0, 99 => 1792.0},
              relative_less: nil,
              relative_more: nil,
              sample_size: 3,
              std_dev: 0.0,
              std_dev_ips: nil,
              std_dev_ratio: 0.0
            }
          },
          name: "Test 1",
          reductions_data: %Benchee.CollectionData{
            samples: [],
            statistics: %Benchee.Statistics{}
          },
          run_time_data: %Benchee.CollectionData{
            samples: [21580, 2986, 11502],
            statistics: %Benchee.Statistics{
              absolute_difference: nil,
              average: 2854.02659820102,
              ips: 350_382.1585371105,
              maximum: 3_741_076,
              median: 2164.0,
              minimum: 2063,
              mode: 2124,
              percentiles: %{50 => 2164.0, 99 => 5881.0},
              relative_less: nil,
              relative_more: nil,
              sample_size: 3,
              std_dev: 13106.875011228927,
              std_dev_ips: 1_609_100.3359973046,
              std_dev_ratio: 4.592415158110506
            }
          }
        },
        %Benchee.Scenario{
          job_name: "Test 2",
          memory_usage_data: %Benchee.CollectionData{
            samples: [1792, 1792, 1792],
            statistics: %Benchee.Statistics{
              absolute_difference: nil,
              average: 1792.0,
              ips: nil,
              maximum: 1792,
              median: 1792.0,
              minimum: 1792,
              mode: 1792,
              percentiles: %{50 => 1792.0, 99 => 1792.0},
              relative_less: nil,
              relative_more: nil,
              sample_size: 3,
              std_dev: 0.0,
              std_dev_ips: nil,
              std_dev_ratio: 0.0
            }
          },
          name: "Test 2",
          reductions_data: %Benchee.CollectionData{
            samples: [],
            statistics: %Benchee.Statistics{}
          },
          run_time_data: %Benchee.CollectionData{
            samples: [21580, 2986, 11502],
            statistics: %Benchee.Statistics{
              absolute_difference: nil,
              average: 2854.02659820102,
              ips: 350_382.1585371105,
              maximum: 3_741_076,
              median: 2164.0,
              minimum: 2063,
              mode: 2124,
              percentiles: %{50 => 2164.0, 99 => 5881.0},
              relative_less: nil,
              relative_more: nil,
              sample_size: 3,
              std_dev: 13106.875011228927,
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
                  "run_time_maximum",
                  "run_time_median",
                  "run_time_minimum",
                  "run_time_mode",
                  "run_time_sample_size",
                  "run_time_std_dev",
                  "run_time_p_50",
                  "run_time_p_99",
                  "memory_samples",
                  "memory_ips",
                  "memory_average",
                  "memory_maximum",
                  "memory_median",
                  "memory_minimum",
                  "memory_mode",
                  "memory_sample_size",
                  "memory_std_dev",
                  "memory_p_50",
                  "memory_p_99"
                ],
                count: 2
              },
              [
                [
                  "Test 1",
                  [21580, 2986, 11502],
                  350_382.1585371105,
                  2854.02659820102,
                  3_741_076,
                  2164.0,
                  2063,
                  2124,
                  3,
                  13106.875011228927,
                  2164.0,
                  5881.0,
                  [1792, 1792, 1792],
                  nil,
                  1792.0,
                  1792,
                  1792.0,
                  1792,
                  1792,
                  3,
                  0.0,
                  1792.0,
                  1792.0
                ],
                [
                  "Test 2",
                  [21580, 2986, 11502],
                  350_382.1585371105,
                  2854.02659820102,
                  3_741_076,
                  2164.0,
                  2063,
                  2124,
                  3,
                  13106.875011228927,
                  2164.0,
                  5881.0,
                  [1792, 1792, 1792],
                  nil,
                  1792.0,
                  1792,
                  1792.0,
                  1792,
                  1792,
                  3,
                  0.0,
                  1792.0,
                  1792.0
                ]
              ]} = table_results
    end
  end
end
