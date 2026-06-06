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
  import Benchee.IntegrationHelpers
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

  @disable_all_output_options [
    print: [
      fast_warning: false,
      benchmarking: false,
      configuration: false
    ],
    formatters: []
  ]
  test "integration disabling all output configs and formatters we're left with an empty output" do
    output =
      capture_io(fn ->
        Benchee.run(
          %{"Blitz" => fn -> 0 end},
          @test_configuration
          |> Keyword.merge(time: 0.001, warmup: 0)
          |> Keyword.merge(@disable_all_output_options)
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

  test "max_sample_size & multiple inputs with very fast functions" do
    max_sample_size = 3

    configuration =
      @test_configuration
      |> Keyword.merge(@disable_all_output_options)
      |> Keyword.merge(
        max_sample_size: max_sample_size,
        inputs: %{"number_one" => 1, :symbole_one => :one}
      )

    suite =
      Benchee.run(
        %{
          "identity" => fn i -> i end
        },
        configuration
      )

    Enum.each(suite.scenarios, fn scenario ->
      # if this becomes flakey, change to <=
      assert scenario.run_time_data.statistics.sample_size == max_sample_size
    end)
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

      refute Enum.empty?(scenario.run_time_data.samples)
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
end
