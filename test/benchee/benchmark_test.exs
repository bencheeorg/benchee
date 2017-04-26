defmodule Benchee.BenchmarkTest do
  use ExUnit.Case, async: true
  import Benchee.TestHelpers
  alias Benchee.Statistics
  alias Benchee.Benchmark
  alias Benchee.Test.FakeBenchmarkPrinter, as: TestPrinter
  alias Benchee.Suite
  import Benchee.Benchmark

  doctest Benchee.Benchmark

  test ".benchmark adds the job to the jobs to be executed" do
    one_fun = fn -> 1 end
    suite = %Suite{jobs: %{"one" => one_fun}}
    two_fun = fn -> 2 end
    new_suite = benchmark(suite, "two", two_fun)
    assert new_suite == %Suite{jobs: %{"two" => two_fun, "one" => one_fun}}
  end

  test ".benchmark warns when adding a job with the same name again" do
    one_fun = fn -> 1 end
    suite = %Suite{jobs: %{"one" => one_fun}}
    new_suite = benchmark(suite, "one", fn -> 42 end, TestPrinter)

    assert new_suite == %Suite{jobs: %{"one" => one_fun}}

    assert_receive {:duplicate, "one"}
  end

  @config %{parallel: 1,
            time:     40_000,
            warmup:   20_000,
            inputs:   nil,
            print:    %{fast_warning: false, configuration: true}}
  @system %{elixir: "1.4.0", erlang: "19.1"}
  @default_suite %Suite{config: @config, system: @system, jobs: %{}}

  defp test_suite(suite_override \\ %Suite{}) do
    DeepMerge.deep_merge(@default_suite, suite_override)
  end

  test ".measure runs a benchmark suite and enriches it with measurements" do
    retrying fn ->
      suite = test_suite %Suite{config: %{time: 60_000, warmup: 10_000}}
      new_suite =
        suite
        |> benchmark("Name", fn -> :timer.sleep(10) end)
        |> measure(TestPrinter)

      assert new_suite.config == suite.config
      run_times_hash = new_suite.run_times |> no_input_access

      # should be 6 but gotta give it a bit leeway
      assert length(run_times_hash["Name"]) >= 5
    end
  end

  test ".measure runs a suite with multiple jobs and gathers results" do
    retrying fn ->
      suite = test_suite %Suite{config: %{time: 60_000, warmup: 10_000}}
      new_suite =
        suite
        |> benchmark("Name", fn -> :timer.sleep(10) end)
        |> benchmark("Name 2", fn -> :timer.sleep(5) end)
        |> measure(TestPrinter)

      run_times_hash = new_suite.run_times |> no_input_access

      # should be 6 but gotta give it a bit leeway
      assert length(run_times_hash["Name"]) >= 5
      # should be 12, but gotta give it some leeway
      assert length(run_times_hash["Name 2"]) >= 9
      end
  end

  test ".measure can run multiple benchmarks in parallel" do
    suite = test_suite %Suite{
      config: %{parallel: 6, time: 60_000},
      jobs: %{"" => fn -> :timer.sleep 10 end}
    }
    new_suite = measure suite, TestPrinter

    assert %{"" => run_times} = new_suite.run_times |> no_input_access

    # it does more work when working in parallel than it does alone
    assert length(run_times) >= 12
  end

  test ".measure doesn't take longer than advertised for very fast funs" do
    retrying fn ->
      time = 20_000
      warmup = 10_000
      projected = time + warmup

      suite = test_suite %Suite{
                config: %{time: time, warmup: warmup},
                jobs:   %{"" => fn -> :timer.sleep(1) end}
              }
      {time, _} = :timer.tc fn -> measure(suite, TestPrinter) end

      # if the system is too busy there are too many false positives
      leeway = projected * 0.4
      assert_in_delta projected, time, leeway,
                      "excution took too long #{time} vs. #{projected} +- #{leeway}"
    end
  end

  test "variance does not skyrocket on very fast functions" do
    retrying fn ->
      range = 0..10
      stats = %Suite{config: %{time: 150_000, warmup: 20_000}}
              |> test_suite
              |> benchmark("noop", fn -> 1 + 1 end)
              |> benchmark("map", fn ->
                   Enum.map(range, fn(i) -> i end)
                 end)
              |> measure(TestPrinter)
              |> Statistics.statistics
              |> Map.get(:statistics)
              |> no_input_access

      Enum.each stats, fn({_, %{std_dev_ratio: std_dev_ratio}}) ->
        assert std_dev_ratio <= 2.5
      end
    end
  end

  test ".measure never calls the function if warmup and time are 0" do
    ref = self()

    %Suite{config: %{time: 0, warmup: 0},
      jobs: %{"" => fn -> send(ref, :called) end}}
    |> test_suite
    |> Benchmark.measure(TestPrinter)

    refute_receive :called
  end

  test ".measure asks to print te configuration" do
    test_suite()
    |> measure(TestPrinter)

    assert_receive :configuration_information
  end

  test ".measure asks to print what is currently benchmarking" do
    test_suite()
    |> benchmark("Something", fn -> :timer.sleep 10 end)
    |> measure(TestPrinter)

    assert_receive {:benchmarking, "Something"}
  end

  @inputs %{"Arg 1" => "Argument 1", "Arg 2" => "Argument 2"}
  test ".measure calls the functions with the different input arguments" do
    ref = self()

    jobs = %{
      "one" => fn(input) -> send ref, {:one, input} end,
      "two" => fn(input) -> send ref, {:two, input} end
    }
    %Suite{config: %{inputs: @inputs}, jobs: jobs}
    |> test_suite
    |> measure(TestPrinter)

    Enum.each @inputs, fn({_name, value}) ->
      assert_receive {:one, ^value}
      assert_receive {:two, ^value}
    end
  end

  test ".measure notifies which input is being benchmarked now" do
    jobs = %{
      "one" => fn(_) -> nil end
    }
    %Suite{config: %{inputs: @inputs}, jobs: jobs}
    |> test_suite
    |> measure(TestPrinter)

    Enum.each @inputs, fn({name, _value}) ->
      assert_receive {:input_information, ^name}
    end
  end

  test ".measure populates results for all inputs" do
    retrying fn ->
      inputs = %{
        "Short wait"  => 5,
        "Longer wait" => 10
      }
      config = %{time: 60_000,
                 warmup: 10_000,
                 inputs: inputs}
      jobs = %{
        "sleep" => fn(input) -> :timer.sleep(input) end
      }
      results =
        %Suite{config: config, jobs: jobs}
        |> test_suite
        |> measure(TestPrinter)
        |> Map.get(:run_times)

      # should be 12 but the good old leeway
      assert length(results["Short wait"]["sleep"]) >= 9
      # should be 6 but the good old leeway
      assert length(results["Longer wait"]["sleep"]) >= 5
    end
  end

  test ".measure runs the job exactly once if its time exceeds given time" do
    jobs = %{"Sleeps" => fn -> :timer.sleep(2) end}
    run_times =
      %Suite{config: %{time: 1_000, warmup: 0}, jobs: jobs}
      |> test_suite
      |> measure(TestPrinter)
      |> get_in([Access.key!(:run_times), Benchmark.no_input, "Sleeps"])

    assert length(run_times) == 1
  end

  test ".measure stores run times in the right order" do
    {:ok, agent} = Agent.start fn -> 10 end
    increasing_function = fn ->
      Agent.update agent, fn(state) ->
        :timer.sleep state
        state * 2
      end
    end
    jobs = %{"Sleep more" => increasing_function}
    run_times =
      %Suite{config: %{time: 70_000, warmup: 0}, jobs: jobs}
      |> test_suite
      |> measure(TestPrinter)
      |> get_in([Access.key!(:run_times), Benchmark.no_input, "Sleep more"])

    assert length(run_times) >= 2 # should be 3 but good old leeway
    # as the function takes more time each time called run times should be
    # as if sorted ascending
    assert run_times == Enum.sort(run_times)
  end
end
