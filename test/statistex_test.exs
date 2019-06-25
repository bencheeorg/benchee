defmodule Statistex.StatistexTest do
  use ExUnit.Case, async: true
  doctest Statistex

  use ExUnitProperties
  import Statistex
  import StreamData

  describe "property testing as we might get loads of data" do
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

        # mode actually occurs in the samples
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

    property "percentiles are correctly related to each other" do
      check all samples <- list_of(float(), min_length: 1) do
        percies = percentiles(samples, [25, 50, 75, 90, 99])

        assert percies[25] <= percies[50]
        assert percies[50] <= percies[75]
        assert percies[75] <= percies[90]
        assert percies[90] <= percies[99]
      end
    end
  end
end
