defmodule Benchee.ProfileTest do
  # async is set to false because otherwise testing the profilers might lead to failures
  use ExUnit.Case, async: false

  alias Benchee.{
    Benchmark,
    Configuration,
    Profile,
    Suite
  }

  alias Benchee.Test.FakeProfilePrinter, as: TestPrinter

  import ExUnit.CaptureIO

  @config_with_profiler %Configuration{profile_after: true}

  describe ".profile" do
    test "`profile_after` defaults to false, which doesnt profile" do
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
