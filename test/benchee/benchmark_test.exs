defmodule Benchee.BenchmarkTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Benchee.Statistics

  doctest Benchee.Benchmark

  test ".benchmark runs a benchmark and enriches suite with results" do
    capture_io fn ->
      suite = %{config: %{time: 100_000}, jobs: []}
      new_suite = Benchee.benchmark(suite, "Name", fn -> :timer.sleep(10) end)

      assert new_suite.config == suite.config
      assert [{name, run_times}] = new_suite.jobs
      assert name == "Name"
      assert Enum.count(run_times) >= 9 # should be 10 but gotta give it a bit leeway
    end
  end

  test ".benchmark doesn't take longer than advertised for very fast funs" do
    capture_io fn ->
      projected = 10_000
      suite = %{config: %{time: projected}, jobs: []}
      {time, _} = :timer.tc fn -> Benchee.benchmark(suite, "", fn -> 0 end) end

      assert_in_delta projected, time, 500,
                      "excution took too long #{time} vs. #{projected}"
    end
  end

  test "variance does not skyrocket on very fast functions" do
    capture_io fn ->
      range = 0..10
      stats = %{config: %{time: 100_000}, jobs: []}
              |> Benchee.benchmark("noop", fn -> 0 end)
              |> Benchee.benchmark("map", fn ->
                Enum.map(range, fn(i) -> i end)
              end)
              |> Statistics.statistics

      Enum.each stats, fn({_, %{std_dev_ratio: std_dev_ratio}}) ->
        assert std_dev_ratio < 1.2
      end
    end
  end
end
