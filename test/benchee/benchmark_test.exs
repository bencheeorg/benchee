defmodule Benchee.BenchmarkTest do
  use ExUnit.Case, async: true
  import Benchee.TestHelpers
  alias Benchee.Statistics
  alias Benchee.Benchmark
  alias Benchee.Configuration
  alias Benchee.Benchmark.Scenario
  alias Benchee.Test.FakeBenchmarkPrinter, as: TestPrinter
  alias Benchee.Suite
  import Benchee.Benchmark

  doctest Benchee.Benchmark

  describe ".benchmark" do
    # TODO: Delete this test once we're moved over to Benchee.Runner
    test "adds the job to the jobs to be executed" do
      one_fun = fn -> 1 end
      suite = %Suite{jobs: %{"one" => one_fun}}
      two_fun = fn -> 2 end
      new_suite = benchmark(suite, "two", two_fun)
      assert new_suite.jobs == %{"two" => two_fun, "one" => one_fun}
    end

    test "can add jobs with atom keys but converts them to string" do
      suite = %Suite{}
              |> benchmark("one job", fn -> 1 end)
              |> benchmark(:something, fn -> 2 end)

      # TODO: Delete this first assertion once Benchee.Runner is in place
      assert %Suite{jobs: %{"one job" => _, "something" => _}} = suite

      job_names = Enum.map(suite.scenarios, fn(scenario) -> scenario.job_name end)
      assert job_names == ["one job", "something"]
    end

    test "warns when adding the same job again even if it's atom and string" do
      one_fun = fn -> 1 end
      scenario = %Scenario{job_name: "one", function: one_fun}
      suite = %Suite{scenarios: [scenario]}
      new_suite = benchmark(suite, :one, fn -> 42 end, TestPrinter)

      assert new_suite == %Suite{scenarios: [scenario]}

      assert_receive {:duplicate, "one"}
    end

    test "adds a %Scenario{} to the suite for a job with no inputs" do
      job_name = "one job"
      function = fn -> 1 end
      config = %Configuration{inputs: nil}
      suite = benchmark(%Suite{configuration: config}, job_name, function)
      expected_scenario =
        %Scenario{job_name: job_name, function: function,
                  input: Benchmark.no_input(), input_name: Benchmark.no_input()}

      assert suite.scenarios == [expected_scenario]
    end

    test "adds a %Scenario{} to the suite for each input of a job" do
      job_name = "one job"
      function = fn -> 1 end
      config = %Configuration{inputs: %{"large" => 100_000, "small" => 10}}
      suite = benchmark(%Suite{configuration: config}, job_name, function)
      input_names = Enum.map(suite.scenarios, fn(scenario) -> scenario.input_name end)
      inputs = Enum.map(suite.scenarios, fn(scenario) -> scenario.input end)

      assert length(suite.scenarios) == 2
      assert input_names == ["large", "small"]
      assert inputs == [100_000, 10]
    end
  end

  @config %{parallel: 1,
            time:     40_000,
            warmup:   20_000,
            inputs:   nil,
            print:    %{fast_warning: false, configuration: true}}
  @system %{elixir: "1.4.0", erlang: "19.1"}
  @default_suite %Suite{configuration: @config, system: @system, jobs: %{}}

  defp test_suite(suite_override \\ %{}) do
    DeepMerge.deep_merge(@default_suite, suite_override)
  end

  describe ".measure" do
    test "runs a benchmark suite and enriches it with measurements" do
      retrying fn ->
        suite = test_suite %Suite{configuration: %{time: 60_000, warmup: 10_000}}
        new_suite =
          suite
          |> benchmark("Name", fn -> :timer.sleep(10) end)
          |> measure(TestPrinter)

        assert new_suite.configuration == suite.configuration
        run_times_hash = new_suite.run_times |> no_input_access

        # should be 6 but gotta give it a bit leeway
        assert length(run_times_hash["Name"]) >= 5
      end
    end

    test "runs a suite with multiple jobs and gathers results" do
      retrying fn ->
        suite = test_suite %Suite{configuration: %{time: 100_000, warmup: 10_000}}
        new_suite =
          suite
          |> benchmark("Name", fn -> :timer.sleep(19) end)
          |> benchmark("Name 2", fn -> :timer.sleep(9) end)
          |> measure(TestPrinter)

        run_times_hash = new_suite.run_times |> no_input_access

        # should be 5 but gotta give it a bit leeway
        assert length(run_times_hash["Name"]) >= 4
        # should be ~11, but gotta give it some leeway
        assert length(run_times_hash["Name 2"]) >= 8
        end
    end

    test "can run multiple benchmarks in parallel" do
      suite = test_suite %Suite{
        configuration: %{parallel: 6, time: 60_000},
        jobs: %{"" => fn -> :timer.sleep 10 end}
      }
      new_suite = measure suite, TestPrinter

      assert %{"" => run_times} = new_suite.run_times |> no_input_access

      # it does more work when working in parallel than it does alone
      assert length(run_times) >= 12
    end

    test "doesn't take longer than advertised for very fast funs" do
      retrying fn ->
        time = 20_000
        warmup = 10_000
        projected = time + warmup

        suite = test_suite %Suite{
                  configuration: %{time: time, warmup: warmup},
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
        stats = %Suite{configuration: %{time: 150_000, warmup: 20_000}}
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

    test "never calls the function if warmup and time are 0" do
      ref = self()

      %Suite{configuration: %{time: 0, warmup: 0},
        jobs: %{"" => fn -> send(ref, :called) end}}
      |> test_suite
      |> Benchmark.measure(TestPrinter)

      refute_receive :called
    end

    test "asks to print te configuration" do
      test_suite()
      |> measure(TestPrinter)

      assert_receive :configuration_information
    end

    test "asks to print what is currently benchmarking" do
      test_suite()
      |> benchmark("Something", fn -> :timer.sleep 10 end)
      |> measure(TestPrinter)

      assert_receive {:benchmarking, "Something"}
    end

    @inputs %{"Arg 1" => "Argument 1", "Arg 2" => "Argument 2"}
    test "calls the functions with the different input arguments" do
      ref = self()

      jobs = %{
        "one" => fn(input) -> send ref, {:one, input} end,
        "two" => fn(input) -> send ref, {:two, input} end
      }
      %Suite{configuration: %{inputs: @inputs}, jobs: jobs}
      |> test_suite
      |> measure(TestPrinter)

      Enum.each @inputs, fn({_name, value}) ->
        assert_receive {:one, ^value}
        assert_receive {:two, ^value}
      end
    end

    test "notifies which input is being benchmarked now" do
      jobs = %{
        "one" => fn(_) -> nil end
      }
      %Suite{configuration: %{inputs: @inputs}, jobs: jobs}
      |> test_suite
      |> measure(TestPrinter)

      Enum.each @inputs, fn({name, _value}) ->
        assert_receive {:input_information, ^name}
      end
    end

    test "populates results for all inputs" do
      retrying fn ->
        inputs = %{
          "Short wait"  => 9,
          "Longer wait" => 19
        }
        config = %{time: 100_000,
                   warmup: 10_000,
                   inputs: inputs}
        jobs = %{
          "sleep" => fn(input) -> :timer.sleep(input) end
        }
        results =
          %Suite{configuration: config, jobs: jobs}
          |> test_suite
          |> measure(TestPrinter)
          |> Map.get(:run_times)

        # should be ~11 but the good old leeway
        assert length(results["Short wait"]["sleep"]) >= 8
        # should be 5 but the good old leeway
        assert length(results["Longer wait"]["sleep"]) >= 4
      end
    end

    test "runs the job exactly once if its time exceeds given time" do
      jobs = %{"Sleeps" => fn -> :timer.sleep(2) end}
      run_times =
        %Suite{configuration: %{time: 1_000, warmup: 0}, jobs: jobs}
        |> test_suite
        |> measure(TestPrinter)
        |> get_in([Access.key!(:run_times), Benchmark.no_input, "Sleeps"])

      assert length(run_times) == 1
    end

    test "stores run times in the right order" do
      retrying fn ->
        {:ok, agent} = Agent.start fn -> 10 end
        increasing_function = fn ->
          Agent.update agent, fn(state) ->
            :timer.sleep state
            state + 30
          end
        end
        jobs = %{"Sleep more" => increasing_function}
        run_times =
          %Suite{configuration: %{time: 70_000, warmup: 0}, jobs: jobs}
          |> test_suite
          |> measure(TestPrinter)
          |> get_in([Access.key!(:run_times), Benchmark.no_input, "Sleep more"])

        assert length(run_times) >= 2 # should be 3 but good old leeway
        # as the function takes more time each time called run times should be
        # as if sorted ascending
        assert run_times == Enum.sort(run_times)
      end
    end
  end
end
