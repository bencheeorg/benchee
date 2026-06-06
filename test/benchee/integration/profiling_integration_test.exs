defmodule Benchee.ProfilingIntegrationTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO
  import Benchee.TestHelpers

  @test_configuration Benchee.IntegrationHelpers.test_configuration()

  alias Benchee.{Profile, UnknownProfilerError}

  describe "profiling" do
    test "integration profiling defaults to no profile" do
      output =
        capture_io(fn ->
          Benchee.run(%{"Sleeps" => fn -> :timer.sleep(10) end}, @test_configuration)
        end)

      refute output =~ ~r/Profiling.+with/i
      refute output =~ ~r/Profile done/i
    end

    test "integration profiling `profile_after: true` runs default profiler" do
      output =
        capture_io(fn ->
          Benchee.run(
            %{"Sleeps" => fn -> :timer.sleep(10) end},
            Keyword.merge(
              @test_configuration,
              profile_after: true
            )
          )
        end)

      assert output =~ profiling_regex("Sleeps", Profile.default_profiler())
      assert output =~ end_of_profiling_regex(Profile.default_profiler())
    end

    for profiler <- Benchee.Profile.builtin_profilers() do
      @profiler profiler
      test "integration profiling runs #{inspect(@profiler)} profiler" do
        output =
          capture_io(fn ->
            Benchee.run(
              %{"Sleeps" => fn -> :timer.sleep(10) end},
              Keyword.merge(
                @test_configuration,
                profile_after: @profiler
              )
            )
          end)

        assert output =~ profiling_regex("Sleeps", @profiler)
        assert output =~ end_of_profiling_regex(@profiler)
      end
    end

    test "integration profiling a wrong profiler raises exception" do
      assert_raise UnknownProfilerError, fn ->
        capture_io(fn ->
          Benchee.run(
            %{"Sleeps" => fn -> :timer.sleep(10) end},
            Keyword.merge(
              @test_configuration,
              profile_after: :unknown_profiler
            )
          )
        end)
      end
    end

    test "profiling and hooks work together" do
      output =
        capture_io(fn ->
          Benchee.run(
            %{"Sleeps" => fn _arg -> :timer.sleep(10) end},
            Keyword.merge(
              @test_configuration,
              profile_after: true,
              # the value here isn't too important, it just forces the function to take
              # an argument which is what can make it break
              before_each: fn _ -> nil end
            )
          )
        end)

      assert output =~ profiling_regex("Sleeps", Profile.default_profiler())
      assert output =~ end_of_profiling_regex(Profile.default_profiler())
    end

    test "profiling and inputs work together" do
      output =
        capture_io(fn ->
          Benchee.run(
            %{"Sleeps" => fn sleep_time -> :timer.sleep(sleep_time) end},
            Keyword.merge(
              @test_configuration,
              profile_after: true,
              # the value here isn't too important, it just forces the function to take
              # an argument which is what can make it break
              inputs: %{"sleep time" => safe_sleep_time()}
            )
          )
        end)

      assert output =~ profiling_regex("Sleeps", Profile.default_profiler())
      assert output =~ end_of_profiling_regex(Profile.default_profiler())
    end

    defp profiling_regex(benchmark_name, profiler) do
      ~r/Profiling #{benchmark_name} with #{profiler}/
    end

    # :fprof is the only profiler who doesn't have at the end of its output:
    # "Profile done over X matching functions"
    defp end_of_profiling_regex(:fprof) do
      ~r/CNT.+ACC \(ms\).+OWN \(ms\)/
    end

    defp end_of_profiling_regex(_profiler) do
      ~r/Profile done/
    end
  end
end
