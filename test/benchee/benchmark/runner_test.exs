defmodule Benchee.Benchmark.RunnerTest do
  use ExUnit.Case, async: true

  import Benchee.TestHelpers
  import ExUnit.CaptureIO

  alias Benchee.{Benchmark, Configuration, Scenario, Suite}
  alias Benchee.Test.FakeBenchmarkPrinter, as: TestPrinter

  @config %Configuration{
    parallel: 1,
    time: 40_000_000,
    warmup: 20_000_000,
    inputs: nil,
    pre_check: false,
    print: %{fast_warning: false, configuration: true},
    measure_function_call_overhead: false
  }
  @system %{
    elixir: "1.4.0",
    erlang: "19.1",
    num_cores: "4",
    os: "Super Duper",
    available_memory: "8 Trillion",
    cpu_speed: "light speed"
  }
  @default_suite %Suite{configuration: @config, system: @system}

  defp test_suite(suite_override \\ %{}) do
    DeepMerge.deep_merge(@default_suite, suite_override)
  end

  defp run_times_for(suite, job_name, input_name \\ Benchmark.no_input()) do
    filter_fun = fn scenario ->
      scenario.job_name == job_name && scenario.input_name == input_name
    end

    map_fun = fn scenario -> scenario.run_time_data.samples end

    suite.scenarios
    |> Enum.filter(filter_fun)
    |> Enum.flat_map(map_fun)
  end

  describe ".run_scenarios" do
    @tag :performance
    test "runs a benchmark suite and enriches it with measurements" do
      retrying(fn ->
        suite = test_suite(%Suite{configuration: %{time: 60_000_000, warmup: 10_000_000}})

        new_suite =
          suite
          |> Benchmark.benchmark("Name", fn -> :timer.sleep(10) end)
          |> Benchmark.collect(TestPrinter)

        assert new_suite.configuration == suite.configuration
        run_times = run_times_for(new_suite, "Name")

        # should be 6 but gotta give it a bit leeway
        assert length(run_times) >= 5
      end)
    end

    @tag :performance
    test "runs a suite with multiple jobs and gathers results" do
      retrying(fn ->
        suite = test_suite(%Suite{configuration: %{time: 100_000_000, warmup: 10_000_000}})

        new_suite =
          suite
          |> Benchmark.benchmark("Name", fn -> :timer.sleep(19) end)
          |> Benchmark.benchmark("Name 2", fn -> :timer.sleep(9) end)
          |> Benchmark.collect(TestPrinter)

        # should be 5 but gotta give it a bit leeway
        assert length(run_times_for(new_suite, "Name")) >= 4
        # should be ~11, but gotta give it some leeway
        assert length(run_times_for(new_suite, "Name 2")) >= 8
      end)
    end

    test "can run multiple benchmarks in parallel" do
      suite = test_suite(%Suite{configuration: %{parallel: 3, time: 60_000_000}})

      new_suite =
        suite
        |> Benchmark.benchmark("", fn -> :timer.sleep(10) end)
        |> Benchmark.collect(TestPrinter)

      # it does more work when working in parallel than it does alone,
      # alone it should only manage to do ~6 (10ms sleep, 60ms time)
      # very lenient because... CI.
      assert length(run_times_for(new_suite, "")) >= 8
    end

    test "combines results for parallel benchmarks into a single scenario" do
      suite = test_suite(%Suite{configuration: %{parallel: 4, time: 60_000_000}})

      new_suite =
        suite
        |> Benchmark.benchmark("", fn -> :timer.sleep(10) end)
        |> Benchmark.collect(TestPrinter)

      assert length(new_suite.scenarios) == 1
    end

    @tag :memory_measure
    test "measures the memory usage of a scenario" do
      suite =
        test_suite(%Suite{configuration: %{time: 60_000, warmup: 10_000, memory_time: 30_000}})

      new_suite =
        suite
        |> Benchmark.benchmark("Name", fn ->
          Enum.map(0..100, fn _ -> [12.23, 30.536, 30.632, 7398.3295] end)
        end)
        |> Benchmark.collect(TestPrinter)

      memory_usages = List.first(new_suite.scenarios).memory_usage_data.samples

      assert length(memory_usages) > 0
    end

    test "measures the reduction count of a scenario" do
      suite =
        test_suite(%Suite{
          configuration: %{time: 60_000, warmup: 10_000, reduction_time: 2_000_000}
        })

      new_suite =
        suite
        |> Benchmark.benchmark("Name", fn ->
          Enum.map(0..100, fn _ -> [12.23, 30.536, 30.632, 7398.3295] end)
        end)
        |> Benchmark.collect(TestPrinter)

      reduction_counts = hd(new_suite.scenarios).reductions_data.samples

      assert length(reduction_counts) > 0
      assert Enum.all?(reduction_counts, fn count -> count >= 347 and count <= 567 end)
    end

    @tag :memory_measure
    test "records memory when the function only runs once" do
      suite = test_suite(%Suite{configuration: %{time: 0.0, warmup: 0.0, memory_time: 1_000_000}})

      new_suite =
        suite
        |> Benchmark.benchmark("Name", fn ->
          Enum.map(0..1000, fn _ -> [12.23, 30.536, 30.632, 7398.3295] end)
        end)
        |> Benchmark.collect(TestPrinter)

      memory_usages = List.first(new_suite.scenarios).memory_usage_data.samples

      assert length(memory_usages) > 0
    end

    @tag :memory_measure
    test "correctly scales down memory usage of very fast functions" do
      suite = test_suite(%Suite{configuration: %{time: 0.0, warmup: 1, memory_time: 1_000_000}})

      new_suite =
        suite
        |> Benchmark.benchmark("Boom", fn -> Enum.map([1, 2, 3], fn i -> i + 1 end) end)
        |> Benchmark.collect(TestPrinter)

      memory_usages = List.first(new_suite.scenarios).memory_usage_data.samples

      assert [memory_consumption] = Enum.uniq(memory_usages)
      assert memory_consumption >= 1
      # depending on the number iterations determined, there can be spikes/changes
      assert memory_consumption <= 1_000
    end

    # not fast enough to get fast warnings on nano second accuracy
    @tag :needs_fast_function_repetition
    test "very fast functions print a warning" do
      output =
        capture_io(fn ->
          %Suite{configuration: %{print: %{fast_warning: true}}}
          |> test_suite()
          |> Benchmark.benchmark("", fn -> 1 end)
          |> Benchmark.collect()
        end)

      # need to asser on IO here as our message sending trick doesn't work
      # as we spawn new processes to do our benchmarking work therfore the
      # message never arrives here...
      assert output =~ ~r/Warning.+fast.+unreliable/i
    end

    test "very fast function times are reported correctly" do
      suite =
        test_suite()
        |> Benchmark.benchmark("", fn -> 1 end)
        |> Benchmark.collect(TestPrinter)
        |> Benchee.statistics()

      [%{run_time_data: %{statistics: %{median: median}}}] = suite.scenarios

      # around ~78 on my machine, CI is awful for performance
      assert median < 1500
    end

    test "very fast function times are almost 0 with function call overhead elimination" do
      retrying(fn ->
        suite =
          %{configuration: %{measure_function_call_overhead: true, time: 200_000_000}}
          |> test_suite()
          |> Benchmark.benchmark("", fn -> nil end)
          |> Benchmark.collect(TestPrinter)
          |> Benchee.statistics()

        [%{run_time_data: %{statistics: %{median: median}}}] = suite.scenarios

        # Should be 0 if it works correctly, give a bit of leeway - especially the appveyor CI
        # with Windows has a tougher time here as it repeats the function call
        assert median <= 60
      end)
    end

    @tag :performance
    test "doesn't take longer than advertised for very fast funs" do
      retrying(fn ->
        time = 20_000_000
        warmup = 10_000_000
        projected = time + warmup

        suite =
          %Suite{configuration: %{time: time, warmup: warmup}}
          |> test_suite()
          |> Benchmark.benchmark("", fn -> :timer.sleep(1) end)

        {time, _} =
          Benchmark.Collect.Time.collect(fn -> Benchmark.collect(suite, TestPrinter) end)

        # if the system is too busy there are too many false positives
        leeway = projected * 0.4

        assert_in_delta projected,
                        time,
                        leeway,
                        "excution took too long #{time} vs. #{projected} +- #{leeway}"
      end)
    end

    test "never calls the function if warmup and time are 0" do
      ref = self()

      %Suite{configuration: %{time: 0.0, warmup: 0.0}}
      |> test_suite
      |> Benchmark.benchmark("", fn -> send(ref, :called) end)
      |> Benchmark.collect(TestPrinter)

      refute_receive :called
    end

    test "run times of the scenarios are empty when nothing runs" do
      %{scenarios: [scenario]} =
        %Suite{configuration: %{time: 0.0, warmup: 0.0}}
        |> test_suite
        |> Benchmark.benchmark("don't care", fn -> 0 end)
        |> Benchmark.collect(TestPrinter)

      assert scenario.run_time_data.samples == []
    end

    @no_input Benchmark.no_input()
    test "asks to print what is currently benchmarking" do
      test_suite()
      |> Benchmark.benchmark("Something", fn -> :timer.sleep(10) end)
      |> Benchmark.collect(TestPrinter)

      assert_receive {:benchmarking, "Something", @no_input}
    end

    @inputs %{"Arg 1" => "Argument 1", "Arg 2" => "Argument 2"}

    test "calls the functions with the different input arguments" do
      ref = self()

      %Suite{configuration: %{inputs: @inputs}}
      |> test_suite
      |> Benchmark.benchmark("one", fn input -> send(ref, {:one, input}) end)
      |> Benchmark.benchmark("two", fn input -> send(ref, {:two, input}) end)
      |> Benchmark.collect(TestPrinter)

      Enum.each(@inputs, fn {_name, value} ->
        assert_receive {:one, ^value}
        assert_receive {:two, ^value}
      end)
    end

    test "notifies which input is being benchmarked now" do
      %Suite{configuration: %{inputs: @inputs}}
      |> test_suite
      |> Benchmark.benchmark("one", fn _ -> nil end)
      |> Benchmark.collect(TestPrinter)

      Enum.each(@inputs, fn {name, _value} ->
        assert_received {:benchmarking, "one", ^name}
      end)
    end

    @tag :performance
    test "populates results for all inputs" do
      retrying(fn ->
        inputs = %{
          "Short wait" => 9,
          "Longer wait" => 19
        }

        config = %{time: 100_000_000, warmup: 10_000_000, inputs: inputs}

        new_suite =
          %Suite{configuration: config}
          |> test_suite
          |> Benchmark.benchmark("sleep", fn input -> :timer.sleep(input) end)
          |> Benchmark.collect(TestPrinter)

        # should be ~11 but the good old leeway
        assert length(run_times_for(new_suite, "sleep", "Short wait")) >= 8
        # should be 5 but the good old leeway
        assert length(run_times_for(new_suite, "sleep", "Longer wait")) >= 4
      end)
    end

    test "runs the job exactly once if its time exceeds given time" do
      new_suite =
        %Suite{configuration: %{time: 1, warmup: 0.0}}
        |> test_suite
        |> Benchmark.benchmark("Sleeps", fn -> :timer.sleep(2) end)
        |> Benchmark.collect(TestPrinter)

      assert length(run_times_for(new_suite, "Sleeps")) == 1
    end

    test "stores run times in the right order" do
      retrying(fn ->
        {:ok, agent} = Agent.start(fn -> 10 end)

        increasing_function = fn ->
          Agent.update(agent, fn state ->
            :timer.sleep(state)
            state + 30
          end)
        end

        run_times =
          %Suite{configuration: %{time: 70_000_000, warmup: 0.0}}
          |> test_suite
          |> Benchmark.benchmark("Sleep more", increasing_function)
          |> Benchmark.collect(TestPrinter)
          |> run_times_for("Sleep more")

        # should be 3 but good old leeway
        assert length(run_times) >= 2
        # as the function takes more time each time called run times should be
        # as if sorted ascending
        assert run_times == Enum.sort(run_times)
      end)
    end

    # important for when we load scenarios but want them to run again and not
    # keep or add to them (adding to them makes no sense as they were run on a
    # different machine, just keeping them can be accomplished by loading them
    # after `collect`)
    test "completely overrides existing run times" do
      suite = %Suite{
        scenarios: [
          %Scenario{
            run_time_data: %Benchee.CollectionData{samples: [1_000_000]},
            function: fn -> 1 + 1 end,
            input: @no_input
          }
        ]
      }

      %Suite{scenarios: [scenario]} =
        suite
        |> test_suite
        |> Benchmark.collect(TestPrinter)

      # our previous run time isn't there anymore
      refute Enum.member?(scenario.run_time_data.samples, 1_000_000)
    end

    test "global hooks triggers" do
      me = self()

      %Suite{
        configuration: %{
          warmup: 0.0,
          time: 100,
          before_each: fn input ->
            send(me, :before)
            input
          end,
          after_each: fn _ -> send(me, :after) end
        }
      }
      |> test_suite
      |> Benchmark.benchmark("job", fn -> :timer.sleep(1) end)
      |> Benchmark.collect(TestPrinter)

      assert_received_exactly([:before, :after])
    end

    test "scenario hooks triggers" do
      me = self()

      %Suite{
        configuration: %{
          warmup: 0.0,
          time: 100
        }
      }
      |> test_suite
      |> Benchmark.benchmark(
        "job",
        {fn -> :timer.sleep(1) end,
         before_each: fn input ->
           send(me, :before)
           input
         end,
         after_each: fn _ -> send(me, :after) end,
         before_scenario: fn input ->
           send(me, :before_scenario)
           input
         end,
         after_scenario: fn _ -> send(me, :after_scenario) end}
      )
      |> Benchmark.collect(TestPrinter)

      assert_received_exactly([:before_scenario, :before, :after, :after_scenario])
    end

    test "hooks trigger during warmup and runtime but scenarios once" do
      me = self()

      %Suite{
        configuration: %{
          warmup: 100,
          time: 100
        }
      }
      |> test_suite
      |> Benchmark.benchmark(
        "job",
        {fn -> :timer.sleep(1) end,
         before_each: fn input ->
           send(me, :before)
           input
         end,
         after_each: fn _ -> send(me, :after) end,
         before_scenario: fn input ->
           send(me, :before_scenario)
           input
         end,
         after_scenario: fn _ -> send(me, :after_scenario) end}
      )
      |> Benchmark.collect(TestPrinter)

      assert_received_exactly([
        :before_scenario,
        :before,
        :after,
        :before,
        :after,
        :after_scenario
      ])
    end

    test "hooks trigger for each input" do
      me = self()

      %Suite{
        configuration: %{
          warmup: 0.0,
          time: 100,
          before_each: fn input ->
            send(me, :global_before)
            input
          end,
          after_each: fn _ -> send(me, :global_after) end,
          before_scenario: fn input ->
            send(me, :global_before_scenario)
            input
          end,
          after_scenario: fn _ -> send(me, :global_after_scenario) end,
          inputs: %{"one" => 1, "two" => 2}
        }
      }
      |> test_suite
      |> Benchmark.benchmark(
        "job",
        {fn _ -> :timer.sleep(1) end,
         before_each: fn input ->
           send(me, :local_before)
           input
         end,
         after_each: fn _ -> send(me, :local_after) end,
         before_scenario: fn input ->
           send(me, :local_before_scenario)
           input
         end,
         after_scenario: fn _ -> send(me, :local_after_scenario) end}
      )
      |> Benchmark.collect(TestPrinter)

      assert_received_exactly([
        :global_before_scenario,
        :local_before_scenario,
        :global_before,
        :local_before,
        :local_after,
        :global_after,
        :local_after_scenario,
        :global_after_scenario,
        :global_before_scenario,
        :local_before_scenario,
        :global_before,
        :local_before,
        :local_after,
        :global_after,
        :local_after_scenario,
        :global_after_scenario
      ])
    end

    test "scenario hooks trigger only for that scenario" do
      me = self()

      %Suite{
        configuration: %{
          warmup: 0.0,
          time: 100,
          before_each: fn input ->
            send(me, :global_before)
            input
          end,
          after_each: fn _ -> send(me, :global_after) end,
          after_scenario: fn _ -> send(me, :global_after_scenario) end
        }
      }
      |> test_suite
      |> Benchmark.benchmark(
        "job",
        {fn -> :timer.sleep(1) end,
         before_each: fn input ->
           send(me, :local_1_before)
           input
         end,
         before_scenario: fn input ->
           send(me, :local_scenario_before)
           input
         end}
      )
      |> Benchmark.benchmark("job 2", fn -> :timer.sleep(1) end)
      |> Benchmark.collect(TestPrinter)

      assert_received_exactly([
        :global_before,
        :local_scenario_before,
        :local_1_before,
        :global_after,
        :global_after_scenario,
        :global_before,
        :global_after,
        :global_after_scenario
      ])
    end

    test "different hooks trigger only for that scenario" do
      me = self()

      %Suite{
        configuration: %{
          warmup: 0.0,
          time: 100,
          before_each: fn input ->
            send(me, :global_before)
            input
          end,
          after_each: fn _ -> send(me, :global_after) end
        }
      }
      |> test_suite
      |> Benchmark.benchmark(
        "job",
        {fn -> :timer.sleep(1) end,
         before_each: fn input ->
           send(me, :local_before)
           input
         end,
         after_each: fn _ -> send(me, :local_after) end,
         before_scenario: fn input ->
           send(me, :local_before_scenario)
           input
         end}
      )
      |> Benchmark.benchmark(
        "job 2",
        {fn -> :timer.sleep(1) end,
         before_each: fn input ->
           send(me, :local_2_before)
           input
         end,
         after_each: fn _ -> send(me, :local_2_after) end,
         after_scenario: fn _ -> send(me, :local_2_after_scenario) end}
      )
      |> Benchmark.collect(TestPrinter)

      assert_received_exactly([
        :local_before_scenario,
        :global_before,
        :local_before,
        :local_after,
        :global_after,
        :global_before,
        :local_2_before,
        :local_2_after,
        :global_after,
        :local_2_after_scenario
      ])
    end

    @tag :performance
    test "each triggers for every invocation, scenario once" do
      me = self()

      suite = %Suite{
        configuration: %{
          warmup: 0.0,
          time: 10_000_000,
          before_each: fn input ->
            send(me, :global_before)
            input
          end,
          after_each: fn _ -> send(me, :global_after) end,
          before_scenario: fn input ->
            send(me, :global_before_scenario)
            input
          end,
          after_scenario: fn _ -> send(me, :global_after_scenario) end
        }
      }

      result =
        suite
        |> test_suite
        |> Benchmark.benchmark(
          "job",
          {fn -> :timer.sleep(1) end,
           before_each: fn input ->
             send(me, :local_before)
             input
           end,
           after_each: fn _ -> send(me, :local_after) end,
           before_scenario: fn input ->
             send(me, :local_before_scenario)
             input
           end,
           after_scenario: fn _ -> send(me, :local_after_scenario) end}
        )
        |> Benchmark.collect(TestPrinter)

      {:messages, messages} = Process.info(self(), :messages)

      global_before_sceneario_count =
        Enum.count(messages, fn msg -> msg == :global_before_scenario end)

      local_before_sceneario_count =
        Enum.count(messages, fn msg -> msg == :local_before_scenario end)

      local_after_sceneario_count =
        Enum.count(messages, fn msg -> msg == :local_after_scenario end)

      global_after_sceneario_count =
        Enum.count(messages, fn msg -> msg == :global_after_scenario end)

      assert global_before_sceneario_count == 1
      assert local_before_sceneario_count == 1
      assert local_after_sceneario_count == 1
      assert global_after_sceneario_count == 1

      global_before_count = Enum.count(messages, fn message -> message == :global_before end)
      local_before_count = Enum.count(messages, fn message -> message == :local_before end)
      local_after_count = Enum.count(messages, fn message -> message == :local_after end)
      global_after_count = Enum.count(messages, fn message -> message == :global_after end)

      assert local_before_count == global_before_count
      assert local_after_count == global_after_count
      assert local_before_count == local_after_count
      hook_call_count = local_before_count

      # should be closer to 10 by you know slow CI systems...
      assert hook_call_count >= 2
      # for every sample that we have, we should have run a hook
      [%{run_time_data: %Benchee.CollectionData{samples: run_times}}] = result.scenarios
      sample_size = length(run_times)
      assert sample_size == hook_call_count
    end

    @tag :needs_fast_function_repetition
    test "hooks also trigger for very fast invocations" do
      me = self()

      suite = %Suite{
        configuration: %{
          warmup: 1,
          time: 1_000_000,
          before_each: fn input ->
            send(me, :global_before)
            input
          end,
          after_each: fn _ -> send(me, :global_after) end
        }
      }

      result =
        suite
        |> test_suite
        |> Benchmark.benchmark(
          "job",
          {fn -> 0 end,
           before_each: fn input ->
             send(me, :local_before)
             input
           end,
           after_each: fn _ -> send(me, :local_after) end}
        )
        |> Benchmark.collect(TestPrinter)

      {:messages, messages} = Process.info(self(), :messages)
      global_before_count = Enum.count(messages, fn message -> message == :global_before end)
      local_before_count = Enum.count(messages, fn message -> message == :local_before end)
      local_after_count = Enum.count(messages, fn message -> message == :local_after end)
      global_after_count = Enum.count(messages, fn message -> message == :global_after end)

      assert local_before_count == global_before_count
      assert local_after_count == global_after_count
      assert local_before_count == local_after_count
      hook_call_count = local_before_count

      # we should get a repeat factor of at least 10 and at least a couple
      # of invocations, need to be conservative for CI/slow PCs
      assert hook_call_count > 20

      # we repeat the call but report it back as just one time (average) but
      # we need to run the hooks more often than that (for every iteration)
      [%{run_time_data: %{samples: run_times}}] = result.scenarios
      sample_size = length(run_times)
      assert hook_call_count > sample_size + 10
    end

    test "after_each hooks have access to the return value of the invocation" do
      me = self()

      %Suite{
        configuration: %{
          warmup: 100,
          time: 100,
          after_each: fn out -> send(me, {:global, out}) end
        }
      }
      |> test_suite
      |> Benchmark.benchmark("job", {fn ->
         # still keep to make sure we only get one iteration and not too fast
         :timer.sleep(1)
         :value
       end, after_each: fn out -> send(me, {:local, out}) end})
      |> Benchmark.collect(TestPrinter)

      assert_received_exactly([
        {:global, :value},
        {:local, :value},
        {:global, :value},
        {:local, :value}
      ])
    end

    test "hooks dealing with inputs can adapt it and pass it on" do
      me = self()

      %Suite{
        configuration: %{
          warmup: 1,
          time: 1,
          before_scenario: fn input ->
            send(me, {:global_scenario, input})
            input + 1
          end,
          before_each: fn input ->
            send(me, {:global_each, input})
            input + 1
          end,
          after_scenario: fn input ->
            send(me, {:global_after_scenario, input})
          end,
          inputs: %{"basic input" => 0}
        }
      }
      |> test_suite
      |> Benchmark.benchmark("job", {fn input ->
         # still keep to make sure we only get one iteration and not too fast
         :timer.sleep(1)
         send(me, {:runner, input})
       end,
       before_scenario: fn input ->
         send(me, {:local_scenario, input})
         input + 1
       end,
       before_each: fn input ->
         send(me, {:local_each, input})
         input + 1
       end,
       after_scenario: fn input ->
         send(me, {:local_after_scenario, input})
       end})
      |> Benchmark.collect(TestPrinter)

      assert_received_exactly([
        {:global_scenario, 0},
        {:local_scenario, 1},
        {:global_each, 2},
        {:local_each, 3},
        {:runner, 4},
        {:global_each, 2},
        {:local_each, 3},
        {:runner, 4},
        {:local_after_scenario, 2},
        {:global_after_scenario, 2}
      ])
    end

    test "hooks dealing with inputs still work when there is no input given" do
      me = self()

      %Suite{
        configuration: %{
          warmup: 1,
          time: 1,
          before_scenario: fn input ->
            send(me, {:global_scenario, input})
            input
          end,
          before_each: fn input ->
            send(me, {:global_each, input})
            input
          end,
          after_scenario: fn input ->
            send(me, {:global_after_scenario, input})
          end
        }
      }
      |> test_suite
      |> Benchmark.benchmark("job", {fn ->
         # still keep to make sure we only get one iteration and not too fast
         :timer.sleep(1)
       end,
       before_scenario: fn input ->
         send(me, {:local_scenario, input})
         input
       end,
       before_each: fn input ->
         send(me, {:local_each, input})
         input
       end,
       after_scenario: fn input ->
         send(me, {:local_after_scenario, input})
       end})
      |> Benchmark.collect(TestPrinter)

      no_input = Benchmark.no_input()

      assert_received_exactly([
        {:global_scenario, no_input},
        {:local_scenario, no_input},
        {:global_each, no_input},
        {:local_each, no_input},
        {:global_each, no_input},
        {:local_each, no_input},
        {:local_after_scenario, no_input},
        {:global_after_scenario, no_input}
      ])
    end

    test "runs all benchmarks with all inputs exactly once as a pre check" do
      me = self()

      inputs = %{"small" => 1, "big" => 100}

      config = %{time: 0.0, warmup: 0.0, inputs: inputs, pre_check: true}

      %Suite{configuration: config}
      |> test_suite
      |> Benchmark.benchmark("first", fn input -> send(me, {:first, input}) end)
      |> Benchmark.benchmark("second", fn input -> send(me, {:second, input}) end)
      |> Benchmark.collect(TestPrinter)

      assert_received_exactly([{:first, 100}, {:first, 1}, {:second, 100}, {:second, 1}])
    end

    test "runs all hooks as part of a pre check" do
      me = self()

      config = %{time: 100, warmup: 100, pre_check: true}

      try do
        %Suite{configuration: config}
        |> test_suite
        |> Benchmark.benchmark("first", fn -> send(me, :first) end)
        |> Benchmark.benchmark(
          "job",
          {fn -> send(me, :second) end,
           before_each: fn input ->
             send(me, :before)
             input
           end,
           after_each: fn _ -> send(me, :after) end,
           before_scenario: fn input ->
             send(me, :before_scenario)
             input
           end,
           after_scenario: fn _ ->
             send(me, :after_scenario)
             raise "This fails!"
           end}
        )
        |> Benchmark.collect(TestPrinter)
      rescue
        RuntimeError -> nil
      end

      assert_received_exactly([
        :first,
        :before_scenario,
        :before,
        :second,
        :after,
        :after_scenario
      ])
    end
  end
end
