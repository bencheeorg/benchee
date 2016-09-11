defmodule Benchee.Formatters.ConsoleTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  doctest Benchee.Formatters.Console

  alias Benchee.Formatters.Console

  @config %{console: %{comparison: true}}
  test ".output formats and prints the results right to the console" do
    jobs = %{
      "Second" => %{
        average: 200.0, ips: 5_000.0, std_dev_ratio: 0.1, median: 195.5
      },
      "First"  => %{
        average: 100.0, ips: 10_000.0, std_dev_ratio: 0.1, median: 90.0
      }
    }

    output = capture_io fn ->
      Console.output %{statistics: jobs, config: @config}
    end

    assert output =~ ~r/First/
    assert output =~ ~r/Second/
    assert output =~ ~r/200/
    assert output =~ ~r/5000/
    assert output =~ ~r/10.+%/
    assert output =~ ~r/195.5/
  end

  test ".format sorts the the given stats fastest to slowest" do
    jobs = %{
      "Second" => %{
        average: 200.0, ips: 5_000.0, std_dev_ratio: 0.1, median: 195.5
      },
      "Third"  => %{
        average: 400.0, ips: 2_500.0, std_dev_ratio: 0.1, median: 375.0
      },
      "First"  => %{
        average: 100.0, ips: 10_000.0, std_dev_ratio: 0.1, median: 90.0
      }
    }

    [_header, result_1, result_2, result_3 | _dont_care ] =
      Console.format(%{statistics: jobs, config: @config})

    assert Regex.match?(~r/First/,  result_1)
    assert Regex.match?(~r/Second/, result_2)
    assert Regex.match?(~r/Third/,  result_3)
  end

  test ".format adjusts the label width to longest name" do
    jobs = %{
      "Second" => %{
        average: 200.0, ips: 5_000.0, std_dev_ratio: 0.1, median: 195.5
      },
      "First"  => %{
        average: 100.0, ips: 10_000.0, std_dev_ratio: 0.1, median: 90.0
      }
    }

    expected_width = String.length "Second"
    [header, result_1, result_2 | _dont_care ] =
      Console.format(%{statistics: jobs, config: @config})

    assert_column_width "Name", header, expected_width
    assert_column_width "First", result_1, expected_width
    assert_column_width "Second", result_2, expected_width

    third_name  = String.duplicate("a", 40)
    third_stats = %{average: 400.0, ips: 2_500.0,
                    std_dev_ratio: 0.1, median: 375.0}
    longer_jobs = Map.put jobs, third_name, third_stats

    # Include extra long name, expect width of 40 characters
    expected_width_wide = String.length third_name
    [header, result_1, result_2, result_3 | _dont_care ] =
      Console.format(%{statistics: longer_jobs, config: @config})

    assert_column_width "Name", header, expected_width_wide
    assert_column_width "First", result_1, expected_width_wide
    assert_column_width "Second", result_2, expected_width_wide
    assert_column_width third_name, result_3, expected_width_wide
  end

  test ".format creates comparisons" do
    jobs = %{
      "Second" => %{
        average: 200.0, ips: 5_000.0, std_dev_ratio: 0.1, median: 195.5
      },
      "First"  => %{
        average: 100.0, ips: 10_000.0, std_dev_ratio: 0.1, median: 90.0
      }
    }

    [_, _, _, comp_header, reference, slower] =
      Console.format(%{statistics: jobs, config: @config})

    assert Regex.match? ~r/Comparison/, comp_header
    assert Regex.match? ~r/^First\s+10000.00$/m, reference
    assert Regex.match? ~r/^Second\s+5000.00\s+- 2.00x slower/, slower
  end

  test ".format can omit the comparisons" do
    jobs = %{
      "Second" => %{
        average: 200.0, ips: 5_000.0, std_dev_ratio: 0.1, median: 195.5
      },
      "First"  => %{
        average: 100.0, ips: 10_000.0, std_dev_ratio: 0.1, median: 90.0
      }
    }

    output = Enum.join Console.format(%{statistics: jobs,
                                        config: %{console: %{comparison: false}}})

    refute Regex.match? ~r/Comparison/i, output
    refute Regex.match? ~r/^First\s+10000.00$/m, output
    refute Regex.match? ~r/^Second\s+5000.00\s+- 2.00x slower/, output
  end

  test ".format adjusts the label width to longest name for comparisons" do
    second_name = String.duplicate("a", 40)
    jobs = %{
      second_name => %{
        average: 200.0, ips: 5_000.0, std_dev_ratio: 0.1, median: 195.5
      },
      "First"  => %{
        average: 100.0, ips: 10_000.0, std_dev_ratio: 0.1, median: 90.0
      }
    }

    expected_width = String.length second_name
    [_, _, _, _comp_header, reference, slower] =
      Console.format(%{statistics: jobs, config: @config})

    assert_column_width "First", reference, expected_width
    assert_column_width second_name, slower, expected_width
  end

  test ".format doesn't create comparisons with only one benchmark run" do
    jobs  = %{"First" => %{average: 100.0, ips: 10_000.0,
                           std_dev_ratio: 0.1, median: 90.0}}

    assert [header, result] = Console.format %{statistics: jobs,
                                               config: @config}
    refute Regex.match? ~r/(Comparison|x slower)/, Enum.join([header, result])
  end

  test ".format formats small averages and medians more precisely" do
    fast = %{"First" => %{average: 0.15, ips: 10_000.0,
                          std_dev_ratio: 0.1, median: 0.0125}}

    assert [_, result] = Console.format %{statistics: fast, config: @config}
    assert Regex.match? ~r/0.150\s?μs/, result
    assert Regex.match? ~r/0.0125\s?μs/, result
  end

  test ".format doesn't end in an empty line when there's only on result" do
    fast = %{"First" => %{average: 0.15, ips: 10_000.0,
                          std_dev_ratio: 0.1, median: 0.0125}}

    assert [_, result] = Console.format %{statistics: fast, config: @config}

    assert String.last(result) != "\n"
  end

  test "it doesn't output weird 'e' formats" do
    jobs = %{
      "Job" => %{
        average: 11000.0,
        ips: 12000.0,
        std_dev_ratio: 13000.0,
        median: 140000.0
      }
    }

    assert [_, result] = Console.format %{statistics: jobs, config: @config}

    refute result =~ ~r/\de\d/
    assert result =~ "11000"
    assert result =~ "12000"
    assert result =~ "13000"
    assert result =~ "14000"
  end

  test ".format doesn't end in an empty line with multiple results" do
    jobs = %{
      "Second" => %{
        average: 200.0, ips: 5_000.0, std_dev_ratio: 0.1, median: 195.5
      },
      "First"  => %{
        average: 100.0, ips: 10_000.0, std_dev_ratio: 0.1, median: 90.0
      }
    }

    [_, _, _, _comp_header, _reference, slower] =
      Console.format(%{statistics: jobs, config: @config})
    assert String.last(slower) != "\n"
  end

  defp assert_column_width(name, string, expected_width) do
    # add 13 characters for the ips column, and an extra space between the columns
    expected_width = expected_width + 14
    n = Regex.escape name
    regex = Regex.compile! "(#{n} +([0-9\.]+|ips))( |$)"
    assert Regex.match? regex, string
    assert expected_width == Regex.run(regex, string, capture: :all_but_first)
                             |> hd
                             |> String.length
  end
end
