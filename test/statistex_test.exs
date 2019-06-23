defmodule Statistex.StatistexTest do
  use ExUnit.Case, async: true
  doctest Statistex

  use ExUnitProperties
  import Statistex
  import StreamData

  property "doesn't blow up no matter what kind of nonempty list of floats it's given" do
    check all samples <- list_of(float(), min_length: 1) do
      stats = statistics(samples)

      assert stats.sample_size >= 1
      assert stats.minimum <= stats.maximum

      assert stats.minimum <= stats.average
      assert stats.average <= stats.maximum

      assert stats.minimum <= stats.median
      assert stats.median <= stats.maximum

      assert stats.median == stats.percentiles[50]

      assert stats.standard_deviation >= 0
      assert stats.standard_deviation_ratio >= 0

      case stats.mode do
        [_ | _] ->
          Enum.each(stats.mode, fn mode ->
            assert(mode in samples)
          end)

        # nothing to do there is no real mode
        nil ->
          nil

        mode ->
          assert mode in samples
      end
    end
  end
end
