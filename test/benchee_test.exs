defmodule BencheeTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  doctest Benchee

  @header_regex         ~r/Name.+ips.+average.+deviation/
  @sleep_benchmark_rgex ~r/Sleeps\s+\d+.+\s+\d+\.\d+.+\s+.+\d+\.\d+/
  test "integration" do
    capture_io fn ->
      result =
        Benchee.init(%{time: 0.1})
        |> Benchee.benchmark("Sleeps", fn -> :timer.sleep(10) end)
        |> Benchee.Statistics.statistics
        |> Benchee.Formatters.String.format

      [header, benchmark_stats] = result
      assert Regex.match?(@header_regex, header)
      assert Regex.match?(@sleep_benchmark_rgex, benchmark_stats)
    end
  end
end
