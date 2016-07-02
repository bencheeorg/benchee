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

  test "adjusts the label width to longest name" do
    third_name = String.duplicate("a", 40)
    first  = {"First",  %{average: 100.0, ips: 10_000.0,
                          std_dev_ratio: 0.1, median: 90.0}}
    second = {"Second", %{average: 200.0, ips: 5_000.0,
                          std_dev_ratio: 0.1, median: 195.5}}
    third  = {third_name,  %{average: 400.0, ips: 2_500.0,
                             std_dev_ratio: 0.1, median: 375.0}}

    expected_width = 43 # Normally long names, expect default width of 30 + 13
    [header, result_1, result_2 | _dont_care ] = Console.format([first, second])

    assert_column_width "Name", header, expected_width
    assert_column_width "First", result_1, expected_width
    assert_column_width "Second", result_2, expected_width

    expected_width_wide = 54 # Include extra long name, expect width of 41 + 13
    [header, result_1, result_2, result_3 | _dont_care ] = Console.format([first, second, third])

    assert_column_width "Name", header, expected_width_wide
    assert_column_width "First", result_1, expected_width_wide
    assert_column_width "Second", result_2, expected_width_wide
    assert_column_width third_name, result_3, expected_width_wide
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

  test "adjusts the label width to longest name for comparisons" do
    second_name = String.duplicate("a", 40)
    first  = {"First",  %{average: 100.0, ips: 10_000.0,
                          std_dev_ratio: 0.1, median: 90.0}}
    second  = {second_name,  %{average: 400.0, ips: 2_500.0,
                               std_dev_ratio: 0.1, median: 375.0}}

    expected_width = 54 # With extra long name, expect width of 41 + 13
    [_, _, _, _comp_header, reference, slower] = Console.format([first, second])

    assert_column_width "First", reference, expected_width
    assert_column_width second_name, slower, expected_width
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

  defp assert_column_width(name, string, expected_width) do
    n = Regex.escape name
    regex = Regex.compile! "(#{n} +([0-9\.]+|ips))( |$)"
    assert Regex.match? regex, string
    assert expected_width == Regex.run(regex, string, capture: :all_but_first)
      |> hd() |> String.length()
  end
end
