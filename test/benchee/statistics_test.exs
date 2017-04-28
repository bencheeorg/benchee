defmodule Benchee.StatistcsTest do
  use ExUnit.Case, async: true
  alias Benchee.{Statistics, Suite}
  doctest Benchee.Statistics

  @sample_1 [600, 470, 170, 430, 300]
  @sample_2 [17, 15, 23, 7, 9, 13]
  test ".statistics computes the statistics for all jobs correctly" do
    suite = %Suite{
      run_times: %{
        "Input" => %{
          "Job 1" => @sample_1,
          "Job 2" => @sample_2
        }
      }
    }

    %Suite{
      statistics: %{
        "Input" => %{
          "Job 1" => stats_1,
          "Job 2" => stats_2}}} = Statistics.statistics suite

    sample_1_asserts(stats_1)
    sample_2_asserts(stats_2)
  end

  test ".statistics computes statistics correctly for multiple inputs" do
    suite = %Suite{
      run_times: %{
        "Input 1" => %{
          "Job" => @sample_1
        },
        "Input 2" => %{
          "Job" => @sample_2
        }
      }
    }

    %Suite{
      statistics: %{
        "Input 1" => %{
          "Job" => stats_1
        },
        "Input 2" => %{
          "Job" => stats_2}}} = Statistics.statistics suite

    sample_1_asserts(stats_1)
    sample_2_asserts(stats_2)
  end

  defp sample_1_asserts(stats) do
    assert stats.average == 394.0
    assert_in_delta stats.std_dev, 147.32, 0.01
    assert_in_delta stats.std_dev_ratio, 0.37, 0.01
    assert_in_delta stats.ips, 2538, 1
    assert stats.median == 430.0
    assert stats.minimum == 170
    assert stats.maximum == 600
    assert stats.sample_size == 5
  end

  defp sample_2_asserts(stats) do
    assert stats.average == 14.0
    assert_in_delta stats.std_dev, 5.25, 0.01
    assert_in_delta stats.std_dev_ratio, 0.37, 0.01
    assert_in_delta stats.ips, 71428, 1
    assert stats.median == 14.0
    assert stats.minimum == 7
    assert stats.maximum == 23
    assert stats.sample_size == 6
  end

  test ".statistics preserves all other keys in the map handed to it" do
    suite = %Suite{
      run_times: %{
        "Input" => %{
          "Job 1" => [600, 470, 170, 430, 300],
          "Job 2" => [17, 15, 23, 7, 9, 13]
        }
      },
      config: %{formatters: []}
    }

    assert %Suite{config: %{formatters: []}} =
      Statistics.statistics suite
  end

  test ".sort sorts the benchmarks correctly and retains all data" do
    fourth = {"Fourth", %{average: 400.1, ips: 4_999.0,  std_dev_ratio: 0.7}}
    second = {"Second", %{average: 200.0, ips: 5_000.0,  std_dev_ratio: 2.1}}
    third  = {"Third",  %{average: 400.0, ips: 2_500.0,  std_dev_ratio: 1.5}}
    first  = {"First",  %{average: 100.0, ips: 10_000.0, std_dev_ratio: 0.3}}
    jobs = Map.new [fourth, second, third, first]

    assert Statistics.sort(jobs) == [first, second, third, fourth]
  end
end
