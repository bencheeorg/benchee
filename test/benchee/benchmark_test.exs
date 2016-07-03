defmodule Benchee.BenchmarkTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Benchee.Statistics
  alias Benchee.Benchmark

  doctest Benchee.Benchmark

  test ".benchmark adds the job to the jobs to be executed" do
    one_fun = fn -> 1 end
    suite = %{jobs: [{"one", one_fun}]}
    two_fun = fn -> 2 end
    new_suite = Benchee.benchmark(suite, "two", two_fun)
    assert new_suite == %{jobs: [{"two", two_fun}, {"one", one_fun}]}
  end

  test ".measure runs a benchmark suite and enriches it with results" do
    capture_io fn ->
      suite = %{config: %{parallel: 1, time: 100_000, warmup: 0}, jobs: []}
      new_suite =
        suite
        |> Benchee.benchmark("Name", fn -> :timer.sleep(10) end)
        |> Benchee.measure

      assert new_suite.config == suite.config
      assert [{name, run_times}] = new_suite.run_times
      assert name == "Name"
      assert length(run_times) == 1
      # should be 9 (10 minus one prewarm) but gotta give it a bit leeway
      assert Enum.count(List.flatten(run_times)) >= 8
    end
  end

  test ".measure can run multiple benchmarks in parallel" do
    capture_io fn ->
      suite = %{config: %{parallel: 10, time: 100_000, warmup: 0}, jobs: [{"", fn -> :timer.sleep 10 end}]}
      new_suite = Benchee.measure suite
      [result1 | _tail] = new_suite.run_times
      {"", run_times} = result1

      assert length(run_times) == 10
      # (as above) should be 90 (100 minus one prewarm per parallel) but gotta give it a bit leeway
      assert length(List.flatten(run_times)) >= 80
    end
  end

  test ".measure doesn't take longer than advertised for very fast funs" do
    capture_io fn ->
      projected = 10_000
      suite = %{config: %{parallel: 1, time: projected, warmup: 0},
                jobs: [{"", fn -> 0 end}]}
      {time, _} = :timer.tc fn -> Benchee.measure(suite) end

      assert_in_delta projected, time, 500,
                      "excution took too long #{time} vs. #{projected}"
    end
  end

  test ".measure doesn't take longer for fast funs even with warmup" do
    capture_io fn ->
      time      = 10_000
      warmup    = 5_000
      projected = time + warmup
      suite = %{config: %{parallel: 1, time: time, warmup: warmup},
                jobs: [{"", fn -> 0 end}]}
      {time, _} = :timer.tc fn -> Benchee.measure(suite) end

      assert_in_delta projected, time, 500,
                      "excution took too long #{time} vs. #{projected}"
    end
  end

  test "variance does not skyrocket on very fast functions" do
    capture_io fn ->
      range = 0..10
      stats = %{config: %{parallel: 1, time: 100_000, warmup: 20_000}, jobs: []}
              |> Benchee.benchmark("noop", fn -> 0 end)
              |> Benchee.benchmark("map", fn ->
                   Enum.map(range, fn(i) -> i end)
                 end)
              |> Benchee.measure
              |> Statistics.statistics

      Enum.each stats, fn({_, %{std_dev_ratio: std_dev_ratio}}) ->
        assert std_dev_ratio < 1.2
      end
    end
  end

  test ".measure doesn't print out information about warmup (annoying)" do
    output = capture_io fn ->
      %{config: %{parallel: 1, time: 1000, warmup: 500}, jobs: []}
      |> Benchee.benchmark("noop", fn -> 0 end)
      |> Benchee.measure
    end

    refute output =~ ~r/warmup/i
  end

  test ".measure never calls the function if warmup and time are 0" do
    output = capture_io fn ->
      %{config: %{parallel: 1, time: 0, warmup: 0}, jobs: [{"", fn -> IO.puts "called" end}]}
      |> Benchmark.measure
    end

    refute output =~ ~r/called/i
  end
end
