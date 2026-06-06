defmodule Benchee.MaxSampleSizeTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO
  import Benchee.Configuration

  alias Benchee.{Configuration, Suite}

  @default_max_sample_size 1_000_000

  test "max_sample_size defaults to 1 million samples" do
    assert %Suite{configuration: %Configuration{max_sample_size: 1_000_000}} = init()
  end

  # Normally we do not test defaults this way, but this covers the full process
  # using the default `max_sample_size` with formatters enabled.
  @tag :performance
  test "max_sample_size by default is set to 1 Million" do
    capture_io(fn ->
      suite =
        Benchee.run(
          %{
            "fast" => fn -> :fast end
          },
          time: 1,
          warmup: 0
        )

      Enum.each(suite.scenarios, fn scenario ->
        assert scenario.run_time_data.statistics.sample_size <= @default_max_sample_size
      end)
    end)
  end

  test "max_sample_size can be disabled" do
    assert %Suite{configuration: %Configuration{max_sample_size: nil}} =
             init(max_sample_size: nil)
  end
end
