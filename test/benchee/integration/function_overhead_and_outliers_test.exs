defmodule Benchee.FunctionOverheadAndOutliersTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO
  import Benchee.IntegrationHelpers
  import Benchee.TestHelpers
  @test_configuration Benchee.IntegrationHelpers.test_configuration()

  describe "function call overhead measurement" do
    @overhead_output_regex ~r/function call overhead.*\d+/i
    test "by default it is off" do
      output =
        capture_io(fn ->
          Benchee.run(
            %{"sleeps" => fn -> sleep_safe_time() end},
            @test_configuration
          )
        end)

      refute output =~ @overhead_output_regex
    end

    test "can be turned on" do
      output =
        capture_io(fn ->
          Benchee.run(
            %{"sleeps" => fn -> sleep_safe_time() end},
            Keyword.merge(@test_configuration, measure_function_call_overhead: true)
          )
        end)

      assert output =~ @overhead_output_regex
    end
  end

  describe "exclude_outliers" do
    test "even with it the high level README example still passes its asserts" do
      output =
        capture_io(fn ->
          list = Enum.to_list(1..10_000)
          map_fun = fn i -> [i, i * i] end

          Benchee.run(
            %{
              "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
              "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
            },
            Keyword.merge(@test_configuration, exclude_outliers: true)
          )
        end)

      readme_sample_asserts(output)
    end

    # The easiest way to create an outlier is to just run something once
    # and then take a "stable" measurement like memory.
    test "removes outliers" do
      counter = :atomics.new(1, [])

      output =
        capture_io(fn ->
          suite =
            Benchee.run(
              %{
                "flawed" => fn ->
                  # Produce some garbage but only once
                  # can't use process dictionary as it's a different process every time.
                  if :atomics.add_get(counter, 1, 1) == 1 do
                    Enum.to_list(1..10_000)
                  end
                end
              },
              time: 0,
              warmup: 0,
              # We need the same number of samples every time, no matter how loaded the machine
              # is (a memory measurement is slow and a single one can use up a short time budget,
              # leaving us with just the outlier). So the time is generous and the number of
              # samples is what stops the measuring - it's not waiting for the time to run out.
              memory_time: 60,
              max_sample_size: 50,
              exclude_outliers: true
            )

          %{scenarios: [%{memory_usage_data: %{samples: samples, statistics: stats}}]} = suite

          assert stats.sample_size == 49
          assert length(samples) == 50

          assert [outlier] = stats.outliers
          assert outlier >= stats.upper_outlier_bound
          # since the outlier is removed, all values are the same
          assert stats.std_dev == 0
          assert stats.minimum == stats.maximum

          # It's a big outlier!
          assert 10 * stats.average < outlier

          # The outlier is only removed from the stats, but not from the samples
          assert outlier in samples
        end)

      # As the outlier is removed, all measurements are the same
      assert output =~ ~r/all.*memory.*same/i
      assert output =~ ~r/exclud.*outlier.*true/i
    end
  end
end
