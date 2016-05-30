defmodule BencheeTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  doctest Benchee

  @header_regex         ~r/^Name.+ips.+average.+deviation$/m
  @sleep_benchmark_regex ~r/^Sleeps\s+\d+.+\s+\d+\.\d+.+\s+.+\d+\.\d+/m
  @magic_benchmark_regex ~r/^Magic\s+\d+.+\s+\d+\.\d+.+\s+.+\d+\.\d+/m
  test "integration step by step" do
    capture_io fn ->
      result =
        Benchee.init(%{time: 0.1})
        |> Benchee.benchmark("Sleeps", fn -> :timer.sleep(10) end)
        |> Benchee.Statistics.statistics
        |> Benchee.Formatters.String.format

      [header, benchmark_stats] = result
      assert Regex.match?(@header_regex, header)
      assert Regex.match?(@sleep_benchmark_regex, benchmark_stats)
    end
  end

  test "integration high level interface .run" do
    output = capture_io fn ->
      Benchee.run(%{time: 0.1}, [{"Sleeps", fn -> :timer.sleep(10) end}])
    end

    assert Regex.match?(@header_regex, output)
    assert Regex.match?(@sleep_benchmark_regex, output)
  end

  test "integration multiple funs in .run" do
    output = capture_io fn ->
      Benchee.run(%{time: 0.1},
                  [{"Sleeps", fn -> :timer.sleep(10) end},
                   {"Magic", fn -> Enum.to_list(1..100)  end}])
    end

    assert Regex.match?(@header_regex, output)
    assert Regex.match?(@sleep_benchmark_regex, output)
    assert Regex.match?(@magic_benchmark_regex, output)
  end
end
