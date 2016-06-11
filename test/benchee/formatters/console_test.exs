defmodule Benchee.Formatters.ConsoleTest do
  use ExUnit.Case
  doctest Benchee.Formatters.Console

  alias Benchee.Formatters.Console

  test "sorts the the given stats fastest to slowest" do
    second = {"Second", %{average: 200.0, ips: 5_000.0,
                          std_dev_ratio: 0.1, median: 195.5}}
    third  = {"Third",  %{average: 400.0, ips: 2_500.0,
                          std_dev_ratio: 0.1, median: 375.0}}
    first  = {"First",  %{average: 100.0, ips: 10_000.0,
                          std_dev_ratio: 0.1, median: 90.0}}
    jobs = [second, third, first]

    [_header, result_1, result_2, result_3 | _dont_care ] =
      Console.format(jobs)

    assert Regex.match?(~r/First/,  result_1)
    assert Regex.match?(~r/Second/, result_2)
    assert Regex.match?(~r/Third/,  result_3)
  end

  test "creates comparisons" do
    first  = {"First",  %{average: 100.0, ips: 10_000.0,
                          std_dev_ratio: 0.1, median: 90.0}}
    second = {"Second", %{average: 200.0, ips: 5_000.0,
                          std_dev_ratio: 0.1, median: 195.5}}

    jobs = [second, first]

    [_, _, _, comp_header, reference, slower] = Console.format(jobs)

    assert Regex.match? ~r/Comparison/, comp_header
    assert Regex.match? ~r/^First\s+10000.00$/m, reference
    assert Regex.match? ~r/^Second\s+5000.00\s+- 2.00x slower/, slower
  end

  test "it doesn't create comparisons with only one benchmark run" do
    first  = {"First",  %{average: 100.0, ips: 10_000.0,
                          std_dev_ratio: 0.1, median: 90.0}}

    assert [header, result] = Console.format [first]
    refute Regex.match? ~r/(Comparison|x slower)/, Enum.join([header, result])
  end

  test "It formats small averages and medians more precisely" do
    fast  = {"First",  %{average: 0.15, ips: 10_000.0,
                         std_dev_ratio: 0.1, median: 0.0125}}

    assert [_, result] = Console.format [fast]
    assert Regex.match? ~r/0.150μs/, result
    assert Regex.match? ~r/0.0125μs/, result
  end

  test "it doesn't end in an empty line when there's only on result" do
    fast  = {"First",  %{average: 0.15, ips: 10_000.0,
                         std_dev_ratio: 0.1, median: 0.0125}}

    assert [_, result] = Console.format [fast]

    assert String.last(result) != "\n"
  end

  test "it doesn't end in an empty line with multiple results" do
    first  = {"First",  %{average: 100.0, ips: 10_000.0,
                          std_dev_ratio: 0.1, median: 90.0}}
    second = {"Second", %{average: 200.0, ips: 5_000.0,
                          std_dev_ratio: 0.1, median: 195.5}}

    jobs = [second, first]

    [_, _, _, _comp_header, _reference, slower] = Console.format(jobs)
    assert String.last(slower) != "\n"
  end
end
