defmodule BencheeTest do
  use ExUnit.Case, async: true

  alias Benchee.{
    Conversion.Duration,
    Formatter,
    Formatters.Console,
    Statistics,
    Suite,
    Test.FakeFormatter
  }

  import ExUnit.CaptureIO
  import Benchee.TestHelpers

  doctest Benchee

  @header_regex ~r/^Name.+ips.+average.+deviation.+median.+99th %$/m
  @test_configuration [time: 0.01, warmup: 0.005, measure_function_call_overhead: false]

  test "integration high level README example" do
    output =
      capture_io(fn ->
        list = Enum.to_list(1..10_000)
        map_fun = fn i -> [i, i * i] end

        Benchee.run(
          %{
            "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
            "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
          },
          @test_configuration
        )
      end)

    readme_sample_asserts(output)
  end

  test "integration step by step" do
    capture_io(fn ->
      result =
        @test_configuration
        |> Benchee.init()
        |> Benchee.system()
        |> Benchee.benchmark("Sleeps", fn -> :timer.sleep(10) end)
        |> Benchee.collect()
        |> Statistics.statistics()
        |> Console.format()

      [[_input_name, header, benchmark_stats]] = result
      assert Regex.match?(@header_regex, header)
      assert Regex.match?(body_regex("Sleeps"), benchmark_stats)
    end)
  end

  test "integration high level interface .run" do
    output =
      capture_io(fn ->
        Benchee.run(%{"Sleeps" => fn -> :timer.sleep(10) end}, @test_configuration)
      end)

    assert Regex.match?(@header_regex, output)
    assert Regex.match?(body_regex("Sleeps"), output)
    refute Regex.match?(~r/Compariosn/, output)
    refute Regex.match?(~r/x slower/, output)
  end

  test "integration multiple funs in .run" do
    output =
      capture_io(fn ->
        Benchee.run(
          %{"Sleeps" => fn -> :timer.sleep(10) end, "Magic" => fn -> Enum.to_list(1..100) end},
          @test_configuration
        )
      end)

    assert Regex.match?(@header_regex, output)
    assert Regex.match?(body_regex("Sleeps"), output)
    assert Regex.match?(body_regex("Magic"), output)
  end

  test "integration high level README example but with formatter options" do
    output =
      capture_io(fn ->
        list = Enum.to_list(1..10_000)
        map_fun = fn i -> [i, i * i] end

        Benchee.run(
          %{
            "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
            "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
          },
          @test_configuration ++
            [formatters: [{Console, comparison: true, extended_statistics: true}]]
        )
      end)

    readme_sample_asserts(output)
  end

  test "erlang style :benchee integration" do
    output =
      capture_io(fn ->
        list = Enum.to_list(1..10_000)
        map_fun = fn i -> [i, i * i] end

        :benchee.run(
          %{
            "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
            "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
          },
          @test_configuration
        )
      end)

    readme_sample_asserts(output)
  end

  test "integration expanded README example" do
    output =
      capture_io(fn ->
        list = Enum.to_list(1..10_000)
        map_fun = fn i -> [i, i * i] end

        @test_configuration
        |> Benchee.init()
        |> Benchee.system()
        |> Benchee.benchmark("flat_map", fn -> Enum.flat_map(list, map_fun) end)
        |> Benchee.benchmark("map.flatten", fn -> list |> Enum.map(map_fun) |> List.flatten() end)
        |> Benchee.collect()
        |> Benchee.statistics()
        |> Benchee.relative_statistics()
        |> Console.format()
        |> IO.puts()
      end)

    readme_sample_asserts(output)
  end

  test "integration expanded README sample but using Formatter.output/1" do
    output =
      capture_io(fn ->
        list = Enum.to_list(1..10_000)
        map_fun = fn i -> [i, i * i] end

        configuration = @test_configuration ++ [formatters: [Console]]

        configuration
        |> Benchee.init()
        |> Benchee.system()
        |> Benchee.benchmark("flat_map", fn -> Enum.flat_map(list, map_fun) end)
        |> Benchee.benchmark("map.flatten", fn -> list |> Enum.map(map_fun) |> List.flatten() end)
        |> Benchee.collect()
        |> Benchee.statistics()
        |> Benchee.relative_statistics()
        |> Formatter.output()
      end)

    readme_sample_asserts(output)
  end

  @tag :needs_fast_function_repetition
  test "integration super fast function print warnings" do
    output =
      capture_io(fn ->
        Benchee.run(
          %{"Constant" => fn -> 0 end},
          Keyword.merge(@test_configuration, time: 0.001, warmup: 0)
        )
      end)

    assert output =~ ~r/fast/
    assert output =~ ~r/unreliable/
  end

  @tag :needs_fast_function_repetition
  test "integration super fast function warning is printed once per job" do
    output =
      capture_io(fn ->
        Benchee.run(
          %{"Fast" => fn -> 0 end},
          Keyword.merge(@test_configuration, time: 0.001, warmup: 0.001)
        )
      end)

    warnings =
      output
      |> String.split("\n")
      |> Enum.filter(fn line -> line =~ ~r/Warning:.+fast/ end)

    assert Enum.count(warnings) == 1
  end

  test "integration super fast function warnings can be deactivated" do
    output =
      capture_io(fn ->
        Benchee.run(
          %{"Blitz" => fn -> 0 end},
          Keyword.merge(
            @test_configuration,
            time: 0.001,
            warmup: 0,
            print: [fast_warning: false]
          )
        )
      end)

    refute output =~ ~r/fast/
  end

  test "integration comparison report can be deactivated" do
    output =
      capture_io(fn ->
        Benchee.run(
          %{"Sleeps" => fn -> :timer.sleep(10) end, "Sleeps 2" => fn -> :timer.sleep(20) end},
          Keyword.merge(
            @test_configuration,
            time: 0.01,
            warmup: 0,
            formatters: [{Console, %{comparison: false}}]
          )
        )
      end)

    refute output =~ ~r/compar/i
  end

  test "multiple formatters can be configured and are all called" do
    output =
      capture_io(fn ->
        Benchee.run(
          %{"Sleeps" => fn -> :timer.sleep(10) end},
          Keyword.merge(
            @test_configuration,
            formatters: [
              fn _ -> IO.puts("Formatter one") end,
              fn _ -> IO.puts("Formatter two") end
            ]
          )
        )
      end)

    assert output =~ "Formatter one"
    assert output =~ "Formatter two"
  end

  test "formatters can be supplied as just the module name" do
    output =
      capture_io(fn ->
        list = Enum.to_list(1..10_000)
        map_fun = fn i -> [i, i * i] end

        Benchee.run(
          %{
            "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
            "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
          },
          Keyword.merge(
            @test_configuration,
            formatters: [Console]
          )
        )
      end)

    readme_sample_asserts(output)
  end

  test "formatters can be supplied as a function with arity 1" do
    output =
      capture_io(fn ->
        list = Enum.to_list(1..10_000)
        map_fun = fn i -> [i, i * i] end

        Benchee.run(
          %{
            "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
            "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
          },
          Keyword.merge(
            @test_configuration,
            formatters: [fn suite -> Formatter.output(suite, Console, %{}) end]
          )
        )
      end)

    readme_sample_asserts(output)
  end

  test "for formatters specified as modules format/1 and write/1 are called" do
    capture_io(fn ->
      Benchee.run(
        %{"Sleeps" => fn -> :timer.sleep(10) end},
        Keyword.merge(
          @test_configuration,
          warmup: 0,
          formatters: [
            FakeFormatter,
            FakeFormatter,
            fn _ -> send(self(), :other) end
          ]
        )
      )
    end)

    assert_received_exactly([
      {:write, "output of `format/1` with %{}", %{}},
      {:write, "output of `format/1` with %{}", %{}},
      :other
    ])
  end

  @rough_10_milli_s "((8|9|10|11|12|13|14)\\.\\d{2} ms)"

  @tag :performance
  test "formatters have full access to the suite data, values in assigns" do
    retrying(fn ->
      formatter_one = fn suite ->
        run_time =
          suite.scenarios
          |> (fn [scenario | _] -> List.last(scenario.run_time_data.samples) end).()
          |> Duration.format()

        IO.puts("Run time: #{run_time}")
      end

      formatter_two = fn suite ->
        average =
          suite.scenarios
          |> (fn [scenario | _] -> scenario.run_time_data.statistics.average end).()
          |> Duration.format()

        IO.puts("Average: #{average}")
      end

      formatter_three = fn suite ->
        IO.puts(suite.configuration.assigns.custom)
      end

      output =
        capture_io(fn ->
          Benchee.run(
            %{"Sleeps" => fn -> :timer.sleep(10) end},
            Keyword.merge(
              @test_configuration,
              assigns: %{custom: "Custom value"},
              formatters: [formatter_one, formatter_two, formatter_three]
            )
          )
        end)

      assert output =~ ~r/Run time: #{@rough_10_milli_s}$/m
      assert output =~ ~r/Average: #{@rough_10_milli_s}$/m
      assert output =~ "Custom value"
    end)
  end

  test "inputs feature version of readme example" do
    output =
      capture_io(fn ->
        map_fun = fn i -> [i, i * i] end

        configuration =
          Keyword.merge(
            @test_configuration,
            inputs: %{"list" => Enum.to_list(1..10_000)}
          )

        Benchee.run(
          %{
            "flat_map" => fn input -> Enum.flat_map(input, map_fun) end,
            "map.flatten" => fn input -> input |> Enum.map(map_fun) |> List.flatten() end
          },
          configuration
        )
      end)

    readme_sample_asserts(output)
  end

  test "multiple inputs" do
    output =
      capture_io(fn ->
        map_fun = fn i -> [i, i * i] end

        inputs = [
          inputs: %{
            "small list" => Enum.to_list(1..100),
            "medium list" => Enum.to_list(1..1_000),
            "bigger list" => Enum.to_list(1..10_000)
          }
        ]

        configuration = Keyword.merge(@test_configuration, inputs)

        Benchee.run(
          %{
            "flat_map" => fn input -> Enum.flat_map(input, map_fun) end,
            "map.flatten" => fn input -> input |> Enum.map(map_fun) |> List.flatten() end
          },
          configuration
        )
      end)

    assert String.contains?(output, ["small list", "medium list", "bigger list"])
    occurences = Regex.scan(body_regex("flat_map"), output)
    assert length(occurences) == 3
  end

  test "inputs can also be a list of 2-tuples and it then keeps the order" do
    output =
      capture_io(fn ->
        map_fun = fn i -> [i, i * i] end

        inputs = [
          inputs: [
            {"small list", Enum.to_list(1..100)},
            {"medium list", Enum.to_list(1..1_000)},
            {"bigger list", Enum.to_list(1..10_000)}
          ]
        ]

        configuration = Keyword.merge(@test_configuration, inputs)

        Benchee.run(
          %{
            "flat_map" => fn input -> Enum.flat_map(input, map_fun) end,
            "map.flatten" => fn input -> input |> Enum.map(map_fun) |> List.flatten() end
          },
          configuration
        )
      end)

    assert output =~ ~r/With input small list .*With input medium list.*With input bigger list/s
    occurences = Regex.scan(body_regex("flat_map"), output)
    assert length(occurences) == 3
  end

  test "multiple inputs with very fast functions" do
    output =
      capture_io(fn ->
        inputs = [inputs: %{"number_one" => 1, :symbole_one => :one}]

        configuration = Keyword.merge(@test_configuration, inputs)

        Benchee.run(
          %{
            "identity" => fn i -> i end
          },
          configuration
        )
      end)

    assert output =~ @header_regex

    # fast function warnings only appear on Windows because of none nanosecond precision
    if windows?() do
      assert output =~ ~r/fast/
      assert output =~ ~r/unreliable/
    end

    assert String.contains?(output, ["number_one", "symbol_one"])
    occurences = Regex.scan(body_regex("identity"), output)
    assert length(occurences) == 2
  end

  test ".run returns the suite intact" do
    capture_io(fn ->
      suite =
        Benchee.run(
          %{
            "sleep" => fn -> :timer.sleep(1) end
          },
          Keyword.merge(
            @test_configuration,
            time: 0.001,
            warmup: 0
          )
        )

      assert %Benchee.Suite{scenarios: _, configuration: _} = suite
    end)
  end

  test ".run also adds system information into the mix via Benchee.System" do
    capture_io(fn ->
      suite =
        Benchee.run(
          %{
            "sleep" => fn -> :timer.sleep(1) end
          },
          Keyword.merge(
            @test_configuration,
            time: 0.001,
            warmup: 0
          )
        )

      assert suite.system.elixir != nil
      assert suite.system.erlang != nil
    end)
  end

  test ".run accepts atom keys for jobs" do
    capture_io(fn ->
      suite =
        Benchee.run(
          %{
            sleep: fn -> :timer.sleep(1) end
          },
          Keyword.merge(
            @test_configuration,
            time: 0.001,
            warmup: 0
          )
        )

      assert Enum.map(suite.scenarios, & &1.job_name) == ~w(sleep)
    end)
  end

  test ".run accepts atom keys for inputs" do
    output =
      capture_io(fn ->
        map_fun = fn i -> [i, i * i] end

        inputs = [
          inputs: %{
            "small list" => Enum.to_list(1..100),
            mediumList: Enum.to_list(1..1_000)
          }
        ]

        configuration = Keyword.merge(@test_configuration, inputs)

        Benchee.run(
          %{
            "flat_map" => fn input -> Enum.flat_map(input, map_fun) end,
            "map.flatten" => fn input -> input |> Enum.map(map_fun) |> List.flatten() end
          },
          configuration
        )
      end)

    assert String.contains?(output, ["small list", "mediumList"])
    occurences = Regex.scan(body_regex("flat_map"), output)
    assert length(occurences) == 2
  end

  defmodule MacroTest do
    defmacro add_numbers(num1, num2) do
      quote do
        unquote(num1) + unquote(num2)
      end
    end
  end

  test "works for macros" do
    require MacroTest

    capture_io(fn ->
      %Suite{scenarios: [scenario]} =
        Benchee.run(
          %{
            macro_add: fn -> MacroTest.add_numbers(100, 200) end
          },
          Keyword.merge(
            @test_configuration,
            time: 0.001,
            warmup: 0
          )
        )

      assert length(scenario.run_time_data.samples) > 0
    end)
  end

  describe "edge cases" do
    test "does not blow up setting all times to 0 and never executes a function" do
      output =
        capture_io(fn ->
          Benchee.run(
            %{
              "never execute me" => fn -> raise "BOOOOM" end
            },
            time: 0,
            warmup: 0,
            memory_time: 0
          )
        end)

      refute output =~ "never execute me"
    end

    test "does not blow up if nothing is specified" do
      output =
        capture_io(fn ->
          Benchee.run(
            %{},
            @test_configuration
          )
        end)

      refute output =~ "Benchmarking"
    end
  end

  describe "save & load" do
    test "saving the suite to disk and restoring it" do
      save = [save: [path: "save.benchee", tag: "master"]]
      expected_file = "save.benchee"

      try do
        configuration = Keyword.merge(@test_configuration, save)
        map_fun = fn i -> [i, i * i] end
        list = Enum.to_list(1..10_000)

        capture_io(fn ->
          suite =
            Benchee.run(
              %{
                "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
                "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
              },
              configuration
            )

          content = File.read!(expected_file)

          untagged_suite =
            content
            |> :erlang.binary_to_term()
            |> suite_without_scenario_tags

          assert untagged_suite == suite
        end)

        loaded_output =
          capture_io(fn ->
            Benchee.run(%{}, Keyword.merge(@test_configuration, load: expected_file))
          end)

        readme_sample_asserts(loaded_output, " (master)")

        comparison_output =
          capture_io(fn ->
            Benchee.run(
              %{
                "too fast" => fn -> nil end
              },
              Keyword.merge(@test_configuration, load: expected_file)
            )
          end)

        assert comparison_output =~ ~r/^too fast\s+\d+(\.\d+)?.*+$/m

        assert comparison_output =~
                 ~r/^flat_map \(master\)\s+\d+(\.\d+)?.*- \d+.+x slower \+\d+.+s$/m

        assert comparison_output =~
                 ~r/^map\.flatten \(master\)\s+\d+(\.\d+)?.*- \d+.+x slower \+\d+.+s$/m
      after
        if File.exists?(expected_file) do
          File.rm!(expected_file)
        end
      end
    end
  end

  describe "hooks" do
    test "it runs all of them" do
      capture_io(fn ->
        myself = self()

        Benchee.run(
          %{
            "sleeper" =>
              {fn -> :timer.sleep(1) end,
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
            "sleeper 2" => fn -> :timer.sleep(1) end
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

      assert output =~ "1.00x memory"
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
              reduction_time: 2
            )
          )
        end)

      assert output =~ ~r/Reduction count statistics:/
    end
  end

  @slower_regex "\\s+- \\d+\\.\\d+x slower \\+\\d+(\\.\\d+)?.+"
  defp readme_sample_asserts(output, tag_string \\ "") do
    assert output =~ "warmup: 5 ms"
    assert output =~ "time: 10 ms"

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
    unless windows?(), do: refute(output =~ ~r/fast/i)
  end

  defp body_regex(benchmark_name, tag_regex \\ "") do
    ~r/^#{benchmark_name}#{tag_regex}\s+\d+.+\s+\d+\.?\d*.+\s+.+\d+\.?\d*.+\s+\d+\.?\d*.+/m
  end

  defp windows? do
    {_, os} = :os.type()
    os == :nt
  end
end
