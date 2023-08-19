defmodule Benchee.ProfileTest do
  # async is set to false because otherwise testing the profilers might lead to failures
  # - the profilers are more or less global so running them in parallel can cause problems.
  #
  # Also a good amount of tests (probably should be all) is set to retrying, due to seemingly
  # random failures (the mix task should take care of this, not us):
  # (exit) exited in: :gen_server.call(:eprof, {:profile_start, [], {:_, :_, :_}, {:erlang, :apply,
  # [#Function<16.26155113/0 in Benchee.ProfileTest."..."/1>, []]}, [set_on_spawn: true]},
  # :infinity)** (EXIT) no process: the process is not alive or there's no process currently
  # associated with the given name, possibly because its application isn't started
  use ExUnit.Case, async: false

  import Benchee.TestHelpers
  import ExUnit.CaptureIO

  alias Benchee.{
    Benchmark,
    Configuration,
    Profile,
    Suite
  }

  alias Benchee.Test.FakeProfilePrinter, as: TestPrinter

  @config_with_profiler %Configuration{profile_after: true}

  test "`profile_after` defaults to false, which doesn't profile" do
    %{configuration: %{profile_after: profile_after}} = suite = %Suite{}

    output =
      capture_io(fn ->
        suite
        |> Benchmark.benchmark("one job", fn -> 1 end)
        |> Profile.profile()
      end)

    refute output =~ "Profiling"
    refute profile_after
  end

  test "can profile a benchmark" do
    retrying(fn ->
      output =
        capture_io(fn ->
          %Suite{configuration: @config_with_profiler}
          |> Benchmark.benchmark("one job", fn -> 1 end)
          |> Profile.profile()
        end)

      assert output =~ "Profiling"
    end)
  end

  test "will not profile if no benchmark is found" do
    output =
      capture_io(fn ->
        %Suite{configuration: @config_with_profiler}
        |> Profile.profile()
      end)

    assert output =~ ""
  end

  test "accepts profiler options" do
    configuration = %Configuration{profile_after: profiler_with_opts()}

    output =
      capture_io(fn ->
        %Suite{configuration: configuration}
        |> Benchmark.benchmark("one job", fn -> 1 end)
        |> Profile.profile()
      end)

    assert output =~ ~r/Profiling one job with fprof/
    assert output =~ ~r/CNT.+ACC \(ms\).+OWN \(ms\)/
  end

  test "sends the correct data to the profile printer" do
    name = "one job"
    profiler = :cprof
    configuration = %Configuration{profile_after: profiler}

    capture_io(fn ->
      %Suite{configuration: configuration}
      |> Benchmark.benchmark(name, fn -> 1 end)
      |> Profile.profile(TestPrinter)
    end)

    assert_receive {:profiling, ^name, ^profiler}
  end

  @profilers Profile.builtin_profilers()
  for profiler <- @profilers do
    @profiler profiler
    # can't say warmup as some profilers will have it in the profile messing with the test
    describe "warming up behavior with #{@profiler}" do
      setup _ do
        # lots of odd process not started errors esp. with eprof, trying to remedy... although,
        # the mix task we use already starts them so not sure this helps any...

        @profiler.start()
        :ok
      end

      # can't say warmup in the test description as eprof picks it up and then it matches
      test "the function will be called exactly once by default for profiling" do
        retrying(fn ->
          output = capture_profile_io_and_message_with_config(@profiler)

          assert_received_exactly([:ran])
          refute output =~ ~r/warmup/i
        end)
      end
    end
  end

  # still can't say 'warmup' due to error messages and matching
  describe "general warming up" do
    test "You can still specify you really want to do warmup" do
      retrying(fn ->
        output = capture_profile_io_and_message_with_config({:cprof, warmup: true})

        assert_received_exactly([:ran, :ran])
        assert output =~ ~r/warmup/i
      end)
    end

    test "specifying other options doesn't break the no warmup behavior" do
      retrying(fn ->
        output = capture_profile_io_and_message_with_config({:cprof, something: true})

        assert_received_exactly([:ran])
        refute output =~ ~r/warmup/i
      end)
    end
  end

  defp capture_profile_io_and_message_with_config(opts) do
    output =
      capture_io(fn ->
        test_process = self()

        %Suite{configuration: %Configuration{profile_after: opts}}
        |> Benchmark.benchmark("job", fn -> send(test_process, :ran) end)
        |> Profile.profile()
      end)

    output
  end

  describe "hooks" do
    test "before each hook works" do
      # random flaky failures:      ** (exit) exited in: :gen_server.call(:eprof, {:profile_start, [], {:_, :_, :_}, {:erlang, :apply, [#Function<6.54153602/0 in Benchee.Benchmark.Runner.main_function/2>, []]}, [set_on_spawn: true]}, :infinity)
      retrying(fn ->
        # the mix task we use does this and so we should be fine but worth a go anyhow
        :eprof.start()

        capture_io(fn ->
          test_process = self()

          %Suite{configuration: %Configuration{profile_after: true}}
          |> Benchmark.benchmark(
            "job",
            {fn _ -> 42 end, before_each: fn _ -> send(test_process, :before_each) end}
          )
          |> Profile.profile()
        end)

        assert_received_exactly([:before_each])
      end)
    end

    test "all kinds of hooks with inputs work" do
      retrying(fn ->
        capture_io(fn ->
          test_process = self()

          %Suite{
            configuration: %Configuration{
              profile_after: true,
              inputs: %{"input 1" => 1},
              before_scenario: fn input ->
                send(test_process, {:before_scenario, input})
                input + 1
              end,
              before_each: fn input ->
                send(test_process, {:before_each, input})
                input + 1
              end,
              after_scenario: fn input ->
                send(test_process, {:after_scenario, input})
              end
            }
          }
          |> Benchmark.benchmark("job", fn input ->
            send(test_process, input)
            input + 1
          end)
          |> Profile.profile()
        end)

        assert_received_exactly([
          {:before_scenario, 1},
          {:before_each, 2},
          {:after_scenario, 2}
        ])
      end)
    end

    test "after_each is called in principle" do
      retrying(fn ->
        capture_io(fn ->
          test_process = self()

          %Suite{configuration: %Configuration{profile_after: true}}
          |> Benchmark.benchmark(
            "job",
            {fn -> 42 end, after_each: fn _ -> send(test_process, :after_each) end}
          )
          |> Profile.profile()
        end)

        assert_received_exactly([:after_each])
      end)
    end

    # waiting for release of https://github.com/elixir-lang/elixir/pull/11657
    @tag :skip
    test "after_each doesn't get the function value yet" do
      retrying(fn ->
        capture_io(fn ->
          test_process = self()

          %Suite{configuration: %Configuration{profile_after: true}}
          |> Benchmark.benchmark(
            "job",
            {fn -> 42 end, after_each: fn input -> send(test_process, {:after_each, input}) end}
          )
          |> Profile.profile()
        end)

        assert_received_exactly([{:after_each, 42}])
      end)
    end
  end

  # The example of {:fprof, [sort: :own]} crashes in Elixir version
  # prior to 1.7 because back then they didn't use the atom `:own`
  # but rather its string counterpart.
  #
  # The `accepts profiler options` test should be changed to use
  # the commented `@profile_with_opts` attribute when benchee
  # requires at least Elixir 1.7
  defp profiler_with_opts do
    sort_option =
      if Version.match?(System.version(), ">= 1.7.0") do
        :own
      else
        "own"
      end

    {:fprof, [sort: sort_option]}
  end
end
