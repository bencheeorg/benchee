defmodule Benchee.Benchmark.RunnerTest do
  use ExUnit.Case, async: true
  import Benchee.TestHelpers
  alias Benchee.{Suite, Benchmark, Configuration, Statistics}
  alias Benchee.Test.FakeBenchmarkPrinter, as: TestPrinter

  @config %Configuration{parallel: 1,
                         time:     40_000,
                         warmup:   20_000,
                         inputs:   nil,
                         print:    %{fast_warning: false, configuration: true}}
  @system %{elixir: "1.4.0", erlang: "19.1"}
  @default_suite %Suite{configuration: @config, system: @system}

  defp test_suite(suite_override \\ %{}) do
    DeepMerge.deep_merge(@default_suite, suite_override)
  end

  defp run_times_for(suite, job_name, input_name \\ Benchmark.no_input()) do
    filter_fun = fn(scenario) ->
      scenario.job_name == job_name && scenario.input_name == input_name
    end
    map_fun = fn(scenario) -> scenario.run_times end

    suite.scenarios
    |> Enum.filter(filter_fun)
    |> Enum.flat_map(map_fun)
  end

  describe ".run_scenarios" do
    test "runs a benchmark suite and enriches it with measurements" do
      retrying fn ->
        suite = test_suite(%Suite{configuration: %{time: 60_000, warmup: 10_000}})
        new_suite =
          suite
          |> Benchmark.benchmark("Name", fn -> :timer.sleep(10) end)
          |> Benchmark.measure(TestPrinter)

        assert new_suite.configuration == suite.configuration
        run_times = run_times_for(new_suite, "Name")

        # should be 6 but gotta give it a bit leeway
        assert length(run_times) >= 5
      end
    end

    test "runs a suite with multiple jobs and gathers results" do
      retrying fn ->
        suite = test_suite(%Suite{configuration: %{time: 100_000, warmup: 10_000}})
        new_suite =
          suite
          |> Benchmark.benchmark("Name", fn -> :timer.sleep(19) end)
          |> Benchmark.benchmark("Name 2", fn -> :timer.sleep(9) end)
          |> Benchmark.measure(TestPrinter)

        # should be 5 but gotta give it a bit leeway
        assert length(run_times_for(new_suite, "Name")) >= 4
        # should be ~11, but gotta give it some leeway
        assert length(run_times_for(new_suite, "Name 2")) >= 8
      end
    end

    test "can run multiple benchmarks in parallel" do
      suite = test_suite(%Suite{configuration: %{parallel: 4, time: 60_000}})
      new_suite = suite
                  |> Benchmark.benchmark("", fn -> :timer.sleep 10 end)
                  |> Benchmark.measure(TestPrinter)

      # it does more work when working in parallel than it does alone
      assert length(run_times_for(new_suite, "")) >= 12
    end

    test "very fast function times are reported correctly" do
      suite = test_suite()
              |> Benchmark.benchmark("", fn -> 1 end)
              |> Benchmark.measure(TestPrinter)
              |> Benchee.statistics()

      [%{run_time_statistics: %{average: average}}] = suite.scenarios

      # They are repeated but times are scaled down for the repetition again
      assert average < 10
    end

    test "doesn't take longer than advertised for very fast funs" do
      retrying fn ->
        time = 20_000
        warmup = 10_000
        projected = time + warmup

        suite = %Suite{configuration: %{time: time, warmup: warmup}}
                |> test_suite()
                |> Benchmark.benchmark("", fn -> :timer.sleep(1) end)

        {time, _} = :timer.tc fn -> Benchmark.measure(suite, TestPrinter) end

        # if the system is too busy there are too many false positives
        leeway = projected * 0.4
        assert_in_delta projected, time, leeway,
                        "excution took too long #{time} vs. #{projected} +- #{leeway}"
      end
    end

    test "variance does not skyrocket on very fast functions" do
      retrying fn ->
        range = 0..10
        suite = %Suite{configuration: %{time: 150_000, warmup: 20_000}}
                |> test_suite
                |> Benchmark.benchmark("noop", fn -> 1 + 1 end)
                |> Benchmark.benchmark("map", fn ->
                     Enum.map(range, fn(i) -> i end)
                   end)
                |> Benchmark.measure(TestPrinter)
                |> Statistics.statistics

        stats = Enum.map(suite.scenarios, fn(scenario) -> scenario.run_time_statistics end)

        Enum.each(stats, fn(%Statistics{std_dev_ratio: std_dev_ratio}) ->
          assert std_dev_ratio <= 2.5
        end)
      end
    end

    test "never calls the function if warmup and time are 0" do
      ref = self()

      %Suite{configuration: %{time: 0, warmup: 0}}
      |> test_suite
      |> Benchmark.benchmark("", fn -> send(ref, :called) end)
      |> Benchmark.measure(TestPrinter)

      refute_receive :called
    end

    test "asks to print what is currently benchmarking" do
      test_suite()
      |> Benchmark.benchmark("Something", fn -> :timer.sleep 10 end)
      |> Benchmark.measure(TestPrinter)

      assert_receive {:benchmarking, "Something"}
    end

    @inputs %{"Arg 1" => "Argument 1", "Arg 2" => "Argument 2"}

    test "calls the functions with the different input arguments" do
      ref = self()

      %Suite{configuration: %{inputs: @inputs}}
      |> test_suite
      |> Benchmark.benchmark("one", fn(input) -> send ref, {:one, input} end)
      |> Benchmark.benchmark("two", fn(input) -> send ref, {:two, input} end)
      |> Benchmark.measure(TestPrinter)

      Enum.each @inputs, fn({_name, value}) ->
        assert_receive {:one, ^value}
        assert_receive {:two, ^value}
      end
    end

    test "notifies which input is being benchmarked now" do
      %Suite{configuration: %{inputs: @inputs}}
      |> test_suite
      |> Benchmark.benchmark("one", fn(_) -> nil end)
      |> Benchmark.measure(TestPrinter)

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
        new_suite =
          %Suite{configuration: config}
          |> test_suite
          |> Benchmark.benchmark("sleep", fn(input) -> :timer.sleep(input) end)
          |> Benchmark.measure(TestPrinter)

        # should be ~11 but the good old leeway
        assert length(run_times_for(new_suite, "sleep", "Short wait")) >= 8
        # should be 5 but the good old leeway
        assert length(run_times_for(new_suite, "sleep", "Longer wait")) >= 4
      end
    end

    test "runs the job exactly once if its time exceeds given time" do
      new_suite =
        %Suite{configuration: %{time: 100, warmup: 0}}
        |> test_suite
        |> Benchmark.benchmark("Sleeps", fn -> :timer.sleep(2) end)
        |> Benchmark.measure(TestPrinter)

      assert length(run_times_for(new_suite, "Sleeps")) == 1
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
        run_times =
          %Suite{configuration: %{time: 70_000, warmup: 0}}
          |> test_suite
          |> Benchmark.benchmark("Sleep more", increasing_function)
          |> Benchmark.measure(TestPrinter)
          |> run_times_for("Sleep more")

        assert length(run_times) >= 2 # should be 3 but good old leeway
        # as the function takes more time each time called run times should be
        # as if sorted ascending
        assert run_times == Enum.sort(run_times)
      end
    end

    test "global hooks triggers" do
      me = self()
      %Suite{
        configuration: %{
          warmup: 0,
          time: 100,
          before_each: fn -> send(me, :before) end,
          after_each: fn -> send(me, :after) end
        }
      }
      |> test_suite
      |> Benchmark.benchmark("job", fn -> :timer.sleep 1 end)
      |> Benchmark.measure(TestPrinter)

      assert_received_exactly [:before, :after]
    end

    test "scenario hooks triggers" do
      me = self()
      %Suite{
        configuration: %{
          warmup: 0,
          time: 100
        }
      }
      |> test_suite
      |> Benchmark.benchmark("job", {fn -> :timer.sleep 1 end,
                             before_each: fn -> send(me, :before) end,
                             after_each: fn -> send(me, :after) end})
      |> Benchmark.measure(TestPrinter)

      assert_received_exactly [:before, :after]
    end

    test "hooks trigger during warmup and runtime" do
      me = self()
      %Suite{
        configuration: %{
          warmup: 100,
          time: 100
        }
      }
      |> test_suite
      |> Benchmark.benchmark("job", {fn -> :timer.sleep 1 end,
                             before_each: fn -> send(me, :before) end,
                             after_each:  fn -> send(me, :after) end})
      |> Benchmark.measure(TestPrinter)

      assert_received_exactly [:before, :after, :before, :after]
    end

    test "hooks trigger for each input" do
      me = self()
      %Suite{
        configuration: %{
          warmup: 0,
          time: 100,
          before_each: fn -> send me, :global_before end,
          after_each:  fn -> send me, :global_after end,
          inputs: %{"one" => 1, "two" => 2}
        }
      }
      |> test_suite
      |> Benchmark.benchmark("job", {fn(_) -> :timer.sleep 1 end,
                             before_each: fn -> send me, :local_before end,
                             after_each:  fn -> send me, :local_after end})
      |> Benchmark.measure(TestPrinter)

      assert_received_exactly [
        :global_before, :local_before, :local_after, :global_after,
        :global_before, :local_before, :local_after, :global_after
      ]
    end

    test "scenario hooks trigger only for that scenario" do
      me = self()
      %Suite{
        configuration: %{
          warmup: 0,
          time: 100,
          before_each: fn -> send me, :global_before end,
          after_each:  fn -> send me, :global_after end
        }
      }
      |> test_suite
      |> Benchmark.benchmark("job", {fn -> :timer.sleep 1 end,
                             before_each: fn -> send me, :local_1_before end})
      |> Benchmark.benchmark("job 2", fn -> :timer.sleep 1 end)
      |> Benchmark.measure(TestPrinter)

      assert_received_exactly [
        :global_before, :local_1_before, :global_after,
        :global_before, :global_after
      ]
    end

    test "different hooks trigger only for that scenario" do
      me = self()
      %Suite{
        configuration: %{
          warmup: 0,
          time: 100,
          before_each: fn -> send me, :global_before end,
          after_each:  fn -> send me, :global_after end
        }
      }
      |> test_suite
      |> Benchmark.benchmark("job", {fn -> :timer.sleep 1 end,
                             before_each: fn -> send me, :local_before end,
                             after_each:  fn -> send me, :local_after end})
      |> Benchmark.benchmark("job 2", {fn -> :timer.sleep 1 end,
                             before_each: fn -> send me, :local_2_before end,
                             after_each:  fn -> send me, :local_2_after end})
      |> Benchmark.measure(TestPrinter)

      assert_received_exactly [
        :global_before, :local_before, :local_after, :global_after,
        :global_before, :local_2_before, :local_2_after, :global_after
      ]
    end

    test "before_each triggers for every invocation" do
      me = self()
      suite = %Suite{
                configuration: %{
                  warmup: 0,
                  time: 10_000,
                  before_each: fn -> send me, :global_before end,
                  after_each:  fn -> send me, :global_after end
                }
              }
      result =
        suite
        |> test_suite
        |> Benchmark.benchmark("job", {fn -> :timer.sleep 1 end,
                               before_each: fn -> send me, :local_before end,
                               after_each:  fn -> send me, :local_after end})
        |> Benchmark.measure(TestPrinter)

      {:messages, messages} = Process.info self(), :messages
      global_before_count =
        Enum.count messages, fn(message) -> message == :global_before end
      local_before_count =
        Enum.count messages, fn(message) -> message == :local_before end
      local_after_count =
        Enum.count messages, fn(message) -> message == :local_after end
      global_after_count =
        Enum.count messages, fn(message) -> message == :global_after end


      assert local_before_count == global_before_count
      assert local_after_count == global_after_count
      assert local_before_count == local_after_count
      hook_call_count = local_before_count

      # should be closer to 10 by you know slow CI systems...
      assert hook_call_count >= 2
      # for every sample that we have, we should have run a hook
      [%{run_times: run_times}] = result.scenarios
      sample_size = length(run_times)
      assert sample_size == hook_call_count
    end

    test "hooks also trigger for very fast invocations" do
      me = self()
      suite = %Suite{
                configuration: %{
                  warmup: 0,
                  time: 1_000,
                  before_each: fn -> send me, :global_before end,
                  after_each:  fn -> send me, :global_after end
                }
              }
      result =
        suite
        |> test_suite
        |> Benchmark.benchmark("job", {fn -> 0 end,
                               before_each: fn -> send me, :local_before end,
                               after_each:  fn -> send me, :local_after end})
        |> Benchmark.measure(TestPrinter)

      {:messages, messages} = Process.info self(), :messages
      global_before_count =
        Enum.count messages, fn(message) -> message == :global_before end
      local_before_count =
        Enum.count messages, fn(message) -> message == :local_before end
      local_after_count =
        Enum.count messages, fn(message) -> message == :local_after end
      global_after_count =
        Enum.count messages, fn(message) -> message == :global_after end


      assert local_before_count == global_before_count
      assert local_after_count == global_after_count
      assert local_before_count == local_after_count
      hook_call_count = local_before_count

      # we should get a repeat factor of at least 10 and at least a couple
      # of invocations, need to be conservative for CI/slow PCs
      assert hook_call_count > 20

      # we repeat the call but report it back as just one time (average) but
      # we need to run the hooks more often than that (for every iteration)
      [%{run_times: run_times}] = result.scenarios
      sample_size = length(run_times)
      assert hook_call_count > sample_size + 10
    end

  end
end
