defmodule BencheeTest do
  use ExUnit.Case, async: true

  alias Benchee.{
    Conversion.Duration,
    Formatter,
    Formatters.Console,
    Profile,
    Profile.Benchee.UnknownProfilerError,
    Statistics,
    Suite,
    Test.FakeFormatter
  }

  import ExUnit.CaptureIO
  import Benchee.TestHelpers

  @header_regex ~r/^Name.+ips.+average.+deviation.+median.+99th %$/m
  @test_configuration [time: 0.01, warmup: 0.005]

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

    # The test with the custom functions does not print this
    # so don't want to put it into the general function
    assert output =~ ~r/formatting/i
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
    retrying(fn ->
      output =
        capture_io(fn ->
          Benchee.run(
            %{"Constant" => fn -> 0 end},
            Keyword.merge(@test_configuration, time: 0.001, warmup: 0)
          )
        end)

      assert output =~ ~r/fast/
      assert output =~ ~r/unreliable/
    end)
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

  test "integration disabling all output configs and formatters we're left with an empty output" do
    output =
      capture_io(fn ->
        Benchee.run(
          %{"Blitz" => fn -> 0 end},
          Keyword.merge(
            @test_configuration,
            time: 0.001,
            warmup: 0,
            print: [
              fast_warning: false,
              benchmarking: false,
              configuration: false
            ],
            formatters: []
          )
        )
      end)

    assert output == ""
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
        [scenario] = suite.scenarios

        run_time =
          scenario.run_time_data.samples
          |> List.last()
          |> Duration.format()

        IO.puts("Run time: #{run_time}")
      end

      formatter_two = fn suite ->
        [scenario] = suite.scenarios

        average = Duration.format(scenario.run_time_data.statistics.average)

        IO.puts("Average: #{average}")
      end

      formatter_three = fn suite ->
        IO.puts(suite.configuration.assigns.custom)
      end

      output =
        capture_io(fn ->
          Benchee.run(
            %{"Sleeps" => fn -> :timer.sleep(10) end},
            time: 0.08,
            warmup: 0.03,
            measure_function_call_overhead: false,
            assigns: %{custom: "Custom value"},
            formatters: [formatter_one, formatter_two, formatter_three]
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
    occurrences = Regex.scan(body_regex("flat_map"), output)
    assert length(occurrences) == 3
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
    occurrences = Regex.scan(body_regex("flat_map"), output)
    assert length(occurrences) == 3
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
    occurrences = Regex.scan(body_regex("identity"), output)
    assert length(occurrences) == 2
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
    occurrences = Regex.scan(body_regex("flat_map"), output)
    assert length(occurrences) == 2
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
      save = [save: [path: "save.benchee", tag: "main"]]
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
            |> suite_without_scenario_tags()

          assert untagged_suite == without_functions_and_inputs(suite)
        end)

        loaded_output =
          capture_io(fn ->
            Benchee.run(%{}, Keyword.merge(@test_configuration, load: expected_file))
          end)

        readme_sample_asserts(loaded_output, tag_string: " (main)")

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
                 ~r/^flat_map \(main\)\s+\d+(\.\d+)?.*- \d+.+x slower \+\d+.+s$/m

        assert comparison_output =~
                 ~r/^map\.flatten \(main\)\s+\d+(\.\d+)?.*- \d+.+x slower \+\d+.+s$/m
      after
        if File.exists?(expected_file) do
          File.rm!(expected_file)
        end
      end
    end

    # function and input provide no real benefit for the envisioned use case of comparing outputs
    # what it does is balloon the file size written out and take performance to the groun
    defp without_functions_and_inputs(suite) do
      update_in(suite.scenarios, fn scenarios ->
        Enum.map(scenarios, fn scenario ->
          %Benchee.Scenario{scenario | function: nil, input: nil}
        end)
      end)
    end

    test " report/1 raises without providing at least a load option" do
      assert_raise(ArgumentError, ~r/load/i, fn -> Benchee.report([]) end)
    end

    test "report/1 saving first and then reporting on it" do
      save = [save: [path: "save.benchee", tag: nil]]
      expected_file = "save.benchee"

      try do
        configuration = Keyword.merge(@test_configuration, save)
        map_fun = fn i -> [i, i * i] end
        list = Enum.to_list(1..10_000)

        capture_io(fn ->
          Benchee.run(
            %{
              "flat_map" => fn -> Enum.flat_map(list, map_fun) end,
              "map.flatten" => fn -> list |> Enum.map(map_fun) |> List.flatten() end
            },
            configuration
          )
        end)

        report_output =
          capture_io(fn ->
            Benchee.report(Keyword.merge(@test_configuration, load: expected_file))
          end)

        # no system information, benchmarking config or progress for omitted steps is printed out
        readme_sample_asserts(report_output, benchmarking_prints: false)
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

    @profilers [:cprof, :eprof, :fprof]
    for profiler <- @profilers do
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

  describe "warn when functions are evaluated" do
    test "warns when run in iex" do
      # test env to avoid repeated compilation on CI
      port = Port.open({:spawn, "iex -S mix"}, [:binary, env: [{~c"MIX_ENV", ~c"test"}]])

      try do
        # wait for startup
        # timeout huge because of CI
        assert_receive {^port, {:data, "iex(1)> "}}, 20_000

        send(
          port,
          {self(),
           {:command, "Benchee.run(%{\"test\" => fn -> 1 end}, time: 0.001, warmup: 0)\n"}}
        )

        assert_receive {^port, {:data, "Warning: " <> message}}, 20_000
        assert message =~ ~r/test.+evaluated.+slower.+compiled.+module.+/is

        # waiting for iex to be ready for input again
        assert_receive {^port, {:data, "iex(2)> "}}, 20_000
      after
        # https://elixirforum.com/t/starting-shutting-down-iex-with-a-port-gracefully/60388/2?u=pragtob
        send(port, {self(), {:command, "\a"}})
        send(port, {self(), {:command, "q\n"}})
      end
    end
  end

  describe "escript building" do
    @sample_project_directory Path.expand("fixtures/escript", __DIR__)
    test "benchee can be built into and used as an escript" do
      File.cd!(@sample_project_directory)
      # we don't match the exit_status right now to get better error messages potentially
      {output, exit_status} = System.cmd("bash", ["test.sh"])

      readme_sample_asserts(output)
      assert exit_status == 0
    end
  end

  @slower_regex "\\s+- \\d+\\.\\d+x slower \\+\\d+(\\.\\d+)?.+"
  defp readme_sample_asserts(output, opts \\ [tag_string: "", benchmarking_prints: true]) do
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
