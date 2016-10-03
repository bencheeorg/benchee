defmodule Benchee.StatistcsTest do
  use ExUnit.Case
  alias Benchee.Statistics
  doctest Benchee.Statistics

  test ".statistics computes the statistics for all jobs correctly" do
    suite = %{
      run_times: %{
        "Job 1" => [600, 470, 170, 430, 300],
        "Job 2" => [17, 15, 23, 7, 9, 13]
      }
    }

    %{statistics:
      %{"Job 1" => stats_1,
        "Job 2" => stats_2}} = Statistics.statistics suite

    assert stats_1.average == 394.0
    assert_in_delta stats_1.std_dev, 147.32, 0.01
    assert_in_delta stats_1.std_dev_ratio, 0.37, 0.01
    assert_in_delta stats_1.ips, 2538, 1
    assert stats_1.median == 430.0
    assert stats_1.minimum == 170
    assert stats_1.maximum == 600
    assert stats_1.sample_size == 5

    assert stats_2.average == 14.0
    assert_in_delta stats_2.std_dev, 5.25, 0.01
    assert_in_delta stats_2.std_dev_ratio, 0.37, 0.01
    assert_in_delta stats_2.ips, 71428, 1
    assert stats_2.median == 14.0
    assert stats_2.minimum == 7
    assert stats_2.maximum == 23
    assert stats_2.sample_size == 6
  end

  test ".statistics preserves all other keys in the map handed to it" do
    suite = %{
      run_times: %{
        "Job 1" => [600, 470, 170, 430, 300],
        "Job 2" => [17, 15, 23, 7, 9, 13]
      },
      formatters: [],
      some_option: "value"
    }

    assert %{formatters: [], some_option: "value"} = Statistics.statistics suite
  end

  test ".sort sorts the benchmarks correctly and retains all date" do
    fourth = {"Fourth", %{average: 400.1, ips: 4_999.0,  std_dev_ratio: 0.7}}
    second = {"Second", %{average: 200.0, ips: 5_000.0,  std_dev_ratio: 2.1}}
    third  = {"Third",  %{average: 400.0, ips: 2_500.0,  std_dev_ratio: 1.5}}
    first  = {"First",  %{average: 100.0, ips: 10_000.0, std_dev_ratio: 0.3}}
    jobs = Map.new [fourth, second, third, first]

    assert Statistics.sort(jobs) == [first, second, third, fourth]
  end
end
