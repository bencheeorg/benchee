defmodule Benchee.Formatters.ConsoleTest do
  use ExUnit.Case
  doctest Benchee.Formatters.Console

  test "sorts the the given stats fastest to slowest" do
    second = {"Second", %{average: 200.0, ips: 5_000.0,
                          std_dev_ratio: 0.1, median: 195.5}}
    third  = {"Third",  %{average: 400.0, ips: 2_500.0,
                          std_dev_ratio: 0.1, median: 375.0}}
    first  = {"First",  %{average: 100.0, ips: 10_000.0,
                          std_dev_ratio: 0.1, median: 90.0}}
    jobs = [second, third, first]

    [_header, result_1, result_2, result_3] =
      Benchee.Formatters.Console.format(jobs)

    assert Regex.match?(~r/First/,  result_1)
    assert Regex.match?(~r/Second/, result_2)
    assert Regex.match?(~r/Third/,  result_3)
  end
end
