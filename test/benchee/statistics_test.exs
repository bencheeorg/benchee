defmodule Benchee.StatistcsTest do
  use ExUnit.Case
  doctest Benchee.Statistics

  test "statistics computes the statistics for all jobs correctly" do
    suite = %{run_times: [{"Job 1", [600, 470, 170, 430, 300]},
                          {"Job 2", [17, 15, 23, 7, 9, 13]}]}

    [{_, stats_1}, {_, stats_2}] = Benchee.Statistics.statistics suite

    assert stats_1.average == 394.0
    assert_in_delta stats_1.std_dev, 147.32, 0.01
    assert_in_delta stats_1.std_dev_ratio, 0.37, 0.01
    assert_in_delta stats_1.ips, 2538, 1
    assert stats_1.median == 430.0

    assert stats_2.average == 14.0
    assert_in_delta stats_2.std_dev, 5.25, 0.01
    assert_in_delta stats_2.std_dev_ratio, 0.37, 0.01
    assert_in_delta stats_2.ips, 71428, 1
    assert stats_2.median == 14.0
  end

  test "sort sorts the benchmarks correctly and retains all date" do
    fourth = {"Fourth", %{average: 400.1, ips: 4_999.0,  std_dev_ratio: 0.7}}
    second = {"Second", %{average: 200.0, ips: 5_000.0,  std_dev_ratio: 2.1}}
    third  = {"Third",  %{average: 400.0, ips: 2_500.0,  std_dev_ratio: 1.5}}
    first  = {"First",  %{average: 100.0, ips: 10_000.0, std_dev_ratio: 0.3}}
    jobs = [fourth, second, third, first]

    assert Benchee.Statistics.sort(jobs) == [first, second, third, fourth]
  end
end
