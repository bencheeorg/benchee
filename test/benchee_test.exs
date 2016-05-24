defmodule BencheeTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  doctest Benchee

  test "integration" do
    capture_log fn ->
      result =
        Benchee.init(%{time: 0.1})
        |> Benchee.benchmark("Sleeps", fn -> :timer.sleep(10) end)
        |> Benchee.Statistics.statistics
        |> Benchee.Formatters.String.format

      [header, benchmark_stats] = result
      assert Regex.match?(~r/Name.+ips.+average.+deviation/, header)

      assert Regex.match?(~r/Sleeps/, benchmark_stats)
    end
  end
end
