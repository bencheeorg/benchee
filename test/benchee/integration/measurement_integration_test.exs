defmodule Benchee.MeasurementIntegrationTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  @test_configuration Benchee.IntegrationHelpers.test_configuration()

  describe "memory measurement" do
    @describetag :memory_measure

    test "measures memory usage when instructed to do so" do
      output =
        capture_io(fn ->
          Benchee.run(
            %{"To List" => fn -> Enum.to_list(1..100) end},
            Keyword.merge(
              @test_configuration,
              memory_time: 0.001
            )
          )
        end)

      assert output =~ ~r/Memory usage statistics:/
      assert output =~ ~r/To List\s+[0-9.]{3,} K*B{1}/
    end

    test "does not blow up when only measuring memory times" do
      output =
        capture_io(fn ->
          Benchee.run(
            %{
              "something" => fn -> Enum.map(1..100, fn i -> i + 1 end) end
            },
            Keyword.merge(
              @test_configuration,
              time: 0,
              warmup: 0,
              memory_time: 0.001
            )
          )
        end)

      # no runtime statistics displayed
      refute output =~ ~r/ips/i
      assert output =~ ~r/memory.+statistics/i
    end

    test "the micro keyword list code from Michal does not break memory measurements #213" do
      benches = %{
        "delete old" => fn {kv, key} -> BenchKeyword.delete_v0(kv, key) end,
        "delete reverse" => fn {kv, key} -> BenchKeyword.delete_v2(kv, key) end,
        "delete keymember reverse" => fn {kv, key} -> BenchKeyword.delete_v3(kv, key) end,
        "delete throw" => fn {kv, key} -> BenchKeyword.delete_v1(kv, key) end
      }

      inputs = %{
        "large miss" => {Enum.map(1..100, &{:"k#{&1}", &1}), :k101},
        "large hit" => {Enum.map(1..100, &{:"k#{&1}", &1}), :k100},
        "small miss" => {Enum.map(1..10, &{:"k#{&1}", &1}), :k11}
      }

      output =
        capture_io(fn ->
          Benchee.run(
            benches,
            Keyword.merge(
              @test_configuration,
              inputs: inputs,
              print: [fast_warning: false],
              memory_time: 0.001,
              warmup: 0,
              time: 0
            )
          )
        end)

      refute output =~ "N/A"
      refute output =~ ~r/warning/i
      assert output =~ "large hit"
      # Byte
      assert output =~ "B"

      assert output =~ ~r/1\.0\dx memory/

      assert output =~ "∞ x memo"
    end
  end

  describe "reduction measurement" do
    test "measures reduction count when instructed to do so" do
      output =
        capture_io(fn ->
          Benchee.run(
            %{"To List" => fn -> Enum.to_list(1..100) end},
            Keyword.merge(
              @test_configuration,
              reduction_time: 0.1
            )
          )
        end)

      assert output =~ ~r/Reduction count statistics:/
    end
  end
end
