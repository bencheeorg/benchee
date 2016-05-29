defmodule Benchee.BenchmarkTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

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
end
