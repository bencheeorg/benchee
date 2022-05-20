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
    output =
      capture_io(fn ->
        %Suite{configuration: @config_with_profiler}
        |> Benchmark.benchmark("one job", fn -> 1 end)
        |> Profile.profile()
      end)

    assert output =~ "Profiling"
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

  # can't say warmup as some profilers will have it in the profile messing with the test
  describe "warming up behavior" do
    @profilers Profile.builtin_profilers()

    for profiler <- @profilers do
      @profiler profiler
      # can't say warmup in the test description as eprof picks it up and then it matches
      test "the function will be called exactly once by default for profiling with #{@profiler}" do
        retrying(fn ->
          output =
            capture_io(fn ->
              test_process = self()

              %Suite{configuration: %Configuration{profile_after: @profiler}}
              |> Benchmark.benchmark("job", fn -> send(test_process, :ran) end)
              |> Profile.profile()
            end)

          assert_received_exactly([:ran])
          refute output =~ ~r/warmup/i
        end)
      end
    end

    test "You can still specify you really want to do warmup" do
      output =
        capture_io(fn ->
          test_process = self()

          %Suite{configuration: %Configuration{profile_after: {:cprof, warmup: true}}}
          |> Benchmark.benchmark("job", fn -> send(test_process, :ran) end)
          |> Profile.profile()
        end)

      assert_received_exactly([:ran, :ran])
      assert output =~ ~r/warmup/i
    end

    test "specifying other options doesn't break the no warmup behavior" do
      output =
        capture_io(fn ->
          test_process = self()

          %Suite{configuration: %Configuration{profile_after: {:cprof, something: true}}}
          |> Benchmark.benchmark("job", fn -> send(test_process, :ran) end)
          |> Profile.profile()
        end)

      assert_received_exactly([:ran])
      refute output =~ ~r/warmup/i
    end
  end

  describe "hooks" do
    test "before each hook works" do
      # random flaky failures:      ** (exit) exited in: :gen_server.call(:eprof, {:profile_start, [], {:_, :_, :_}, {:erlang, :apply, [#Function<6.54153602/0 in Benchee.Benchmark.Runner.main_function/2>, []]}, [set_on_spawn: true]}, :infinity)
      retrying(fn ->
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
    end

    test "after_each is called in principle" do
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
    end

    # waiting for release of https://github.com/elixir-lang/elixir/pull/11657
    @tag :skip
    test "after_each doesn't get the function value yet" do
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
