defmodule Benchee.HooksTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO
  import Benchee.TestHelpers
  @test_configuration Benchee.IntegrationHelpers.test_configuration()

  describe "hooks" do
    test "it runs all of them" do
      capture_io(fn ->
        myself = self()

        Benchee.run(
          %{
            "sleeper" =>
              {fn -> sleep_safe_time() end,
               before_each: fn input ->
                 send(myself, :local_before)
                 input
               end,
               after_each: fn _ -> send(myself, :local_after) end,
               before_scenario: fn input ->
                 send(myself, :local_before_scenario)
                 input
               end,
               after_scenario: fn _ -> send(myself, :local_after_scenario) end},
            "sleeper 2" => fn -> sleep_safe_time() end
          },
          Keyword.merge(
            @test_configuration,
            time: 0.0001,
            warmup: 0,
            before_each: fn input ->
              send(myself, :global_before)
              input
            end,
            after_each: fn _ -> send(myself, :global_after) end,
            before_scenario: fn input ->
              send(myself, :global_before_scenario)
              input
            end,
            after_scenario: fn _ -> send(myself, :global_after_scenario) end
          )
        )
      end)

      assert_received_exactly([
        # first job with all those local hooks
        :global_before_scenario,
        :local_before_scenario,
        :global_before,
        :local_before,
        :local_after,
        :global_after,
        :local_after_scenario,
        :global_after_scenario,
        # second job that only runs global hooks
        :global_before_scenario,
        :global_before,
        :global_after,
        :global_after_scenario
      ])
    end
  end
end
