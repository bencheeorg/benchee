defmodule Benchee.StatistcsTest do
  use ExUnit.Case
  doctest Benchee.Statistics

  test "sort sorts the benchmarks correctly and retains all date" do
    fourth = {"Fourth", %{average: 400.1, ips: 4_999.0,  std_dev_ratio: 0.7}}
    second = {"Second", %{average: 200.0, ips: 5_000.0,  std_dev_ratio: 2.1}}
    third  = {"Third",  %{average: 400.0, ips: 2_500.0,  std_dev_ratio: 1.5}}
    first  = {"First",  %{average: 100.0, ips: 10_000.0, std_dev_ratio: 0.3}}
    jobs = [fourth, second, third, first]

    assert Benchee.Statistics.sort(jobs) == [first, second, third, fourth]
  end
end
