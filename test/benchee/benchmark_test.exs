defmodule Benchee.BenchmarkTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Benchee.TestHelpers
  alias Benchee.Statistics
  alias Benchee.Benchmark

  doctest Benchee.Benchmark

  test ".benchmark adds the job to the jobs to be executed" do
    one_fun = fn -> 1 end
    suite = %{jobs: %{"one" => one_fun}}
    two_fun = fn -> 2 end
    new_suite = Benchee.benchmark(suite, "two", two_fun)
    assert new_suite == %{jobs: %{"two" => two_fun, "one" => one_fun}}
  end

  test ".benchmark warns if adding a job with the same name again" do
    output = capture_io fn ->
      one_fun = fn -> 1 end
      suite = %{jobs: %{"one" => one_fun}}
      new_suite = Benchee.benchmark(suite, "one", fn -> 42 end)

      assert new_suite == %{jobs: %{"one" => one_fun}}
    end

    assert output =~ ~r/same name/
  end

  test ".measure runs a benchmark suite and enriches it with results" do
    capture_io fn ->
      suite = %{config: %{parallel: 1, time: 103_000, warmup: 20_000}, jobs: %{}}
      new_suite =
        suite
        |> Benchee.benchmark("Name", fn -> :timer.sleep(10) end)
        |> Benchee.measure

      assert new_suite.config == suite.config
      run_times_hash = new_suite.run_times

      # should be 9 (10 minus one prewarm) but gotta give it a bit leeway
      assert length(run_times_hash["Name"]) >= 8
    end
  end

  test ".measure can run multiple benchmarks in parallel" do
    capture_io fn ->
      suite = %{
        config: %{parallel: 6, time: 103_000, warmup: 20_000},
        jobs: %{"" => fn -> :timer.sleep 10 end}
      }
      new_suite = Benchee.measure suite

      assert %{"" => run_times} = new_suite.run_times

      # it does more work when working in parallel than it does alone
      assert length(run_times) >= 20
    end
  end

  test ".measure doesn't take longer than advertised for very fast funs" do
    capture_io fn ->
      projected = 10_000
      suite = %{config: %{parallel: 1, time: projected, warmup: 0},
                jobs: %{"" => fn -> 0 end}}
      {time, _} = :timer.tc fn -> Benchee.measure(suite) end

      assert_in_delta projected, time, 500,
                      "excution took too long #{time} vs. #{projected}"
    end
  end

  test ".measure doesn't take longer for fast funs even with warmup" do
    retrying fn ->
      capture_io fn ->
        time      = 20_000
        warmup    = 10_000
        projected = time + warmup
        suite = %{config: %{parallel: 1, time: time, warmup: warmup},
                  jobs: %{"" => fn -> 0 end}}
        {time, _} = :timer.tc fn -> Benchee.measure(suite) end

        assert_in_delta projected, time, 2000,
                        "excution took too long #{time} vs. #{projected}"
      end
    end
  end

  test "variance does not skyrocket on very fast functions" do
    retrying fn ->
      capture_io fn ->
        range = 0..10
        stats = %{config: %{parallel: 1,time: 20_000, warmup: 10_000}, jobs: %{}}
                |> Benchee.benchmark("noop", fn -> 0 end)
                |> Benchee.benchmark("map", fn ->
                     Enum.map(range, fn(i) -> i end)
                   end)
                |> Benchee.measure
                |> Statistics.statistics
                |> Map.get(:statistics)

        Enum.each stats, fn({_, %{std_dev_ratio: std_dev_ratio}}) ->
          assert std_dev_ratio < 2.0
        end
      end
    end
  end

  test ".measure doesn't print out information about warmup (annoying)" do
    output = capture_io fn ->
      %{config: %{parallel: 1, time: 1000, warmup: 500}, jobs: %{}}
      |> Benchee.benchmark("noop", fn -> 0 end)
      |> Benchee.measure
    end

    refute output =~ ~r/running.+warmup/i
  end

  test ".measure never calls the function if warmup and time are 0" do
    output = capture_io fn ->
      %{config: %{parallel: 1, time: 0, warmup: 0}, jobs: %{"" => fn -> IO.puts "called" end}}
      |> Benchmark.measure
    end

    refute output =~ ~r/called/i
  end

  test ".measure prints configuration information about the suite" do
    output = capture_io fn ->
      %{config: %{parallel: 2, time: 100_000, warmup: 50_000}, jobs: %{}}
      |> Benchee.benchmark("noop", fn -> 0 end)
      |> Benchee.benchmark("dontcare", fn -> 0 end)
      |> Benchee.measure
    end

    assert output =~ ~r/following configuration/i
    assert output =~ "warmup: 0.05s"
    assert output =~ "time: 0.1s"
    assert output =~ "parallel: 2"
    assert output =~ "Estimated total run time: 0.3s"
  end
end
