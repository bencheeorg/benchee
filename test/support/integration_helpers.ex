defmodule Benchee.IntegrationHelpers do
  @moduledoc false

  import ExUnit.Assertions

  @header_regex ~r/^Name.+ips.+average.+deviation.+median.+99th %$/m
  @slower_regex "\\s+- \\d+\\.\\d+x slower \\+\\d+(\\.\\d+)?.+"
  @test_configuration [time: 0.01, warmup: 0.005]

  def test_configuration, do: @test_configuration

  def readme_sample_asserts(output, opts \\ [tag_string: "", benchmarking_prints: true]) do
    if Access.get(opts, :benchmarking_prints) do
      assert output =~ "warmup: 5 ms"
      assert output =~ "time: 10 ms"
      assert output =~ ~r/calculat.*statistics/i
    end

    tag_string = Access.get(opts, :tag_string, "")

    tag_regex = Regex.escape(tag_string)
    assert output =~ @header_regex
    assert output =~ body_regex("flat_map", tag_regex)
    assert output =~ body_regex("map.flatten", tag_regex)
    assert output =~ ~r/Comparison/, output
    assert output =~ ~r/^map.flatten#{tag_regex}\s+\d+(\.\d+)?\s*.?(#{@slower_regex})?$/m
    assert output =~ ~r/^flat_map#{tag_regex}\s+\d+(\.\d+)?\s*.?(#{@slower_regex})?$/m
    assert output =~ ~r/#{@slower_regex}/m

    # In windows time resolution seems to be milliseconds, hence even
    # standard examples produce a fast warning.
    # So we skip this "basically everything is going fine" test on windows
    if !windows?(), do: refute(output =~ ~r/fast/i)
  end

  def body_regex(benchmark_name, tag_regex \\ "") do
    ~r/^#{benchmark_name}#{tag_regex}\s+\d+.+\s+\d+\.?\d*.+\s+.+\d+\.?\d*.+\s+\d+\.?\d*.+/m
  end

  def windows? do
    {_, os} = :os.type()
    os == :nt
  end
end
