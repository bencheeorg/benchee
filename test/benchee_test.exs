defmodule BencheeTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  import Benchee.TestHelpers
  doctest Benchee

  @header_regex ~r/^Name.+ips.+average.+deviation.+median$/m
  @test_times   [time: 0.01, warmup: 0.005]
  test "integration step by step" do
    capture_io fn ->
      result =
        Benchee.init(@test_times)
        |> Benchee.system
        |> Benchee.benchmark("Sleeps", fn -> :timer.sleep(10) end)
        |> Benchee.measure
        |> Benchee.Statistics.statistics
        |> Benchee.Formatters.Console.format

      [[_input_name, header, benchmark_stats]] = result
      assert Regex.match?(@header_regex, header)
      assert Regex.match?(body_regex("Sleeps"), benchmark_stats)
    end
  end

  test "integration high level interface .run" do
    output = capture_io fn ->
      Benchee.run(%{"Sleeps" => fn -> :timer.sleep(10) end}, @test_times)
    end

    assert Regex.match?(@header_regex, output)
    assert Regex.match?(body_regex("Sleeps"), output)
    refute Regex.match? ~r/Compariosn/, output
    refute Regex.match? ~r/x slower/, output
  end

  test "integration multiple funs in .run" do
    output = capture_io fn ->
      Benchee.run(%{
        "Sleeps" => fn -> :timer.sleep(10) end,
        "Magic"  => fn -> Enum.to_list(1..100) end}, @test_times)
    end

    assert Regex.match?(@header_regex, output)
    assert Regex.match?(body_regex("Sleeps"), output)
    assert Regex.match?(body_regex("Magic"), output)
  end

  test "integration high level README example old school map config" do
    output = capture_io fn ->
      list = Enum.to_list(1..10_000)
      map_fun = fn(i) -> [i, i * i] end

      map_config = Enum.into(@test_times, %{})
      Benchee.run(map_config, %{
        "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
        "map.flatten" =>
          fn -> list |> Enum.map(map_fun) |> List.flatten end
      })
    end

    readme_sample_asserts(output)
  end

  test "integration keywordlist as options in second place" do
    output = capture_io fn ->
      list = Enum.to_list(1..10_000)
      map_fun = fn(i) -> [i, i * i] end

      Benchee.run(%{
        "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
        "map.flatten" =>
          fn -> list |> Enum.map(map_fun) |> List.flatten end
      }, time: 0.01, warmup: 0.005)
    end

    readme_sample_asserts output
  end

  test "erlang style :benchee integration" do
    output = capture_io fn ->
      list = Enum.to_list(1..10_000)
      map_fun = fn(i) -> [i, i * i] end

      :benchee.run(%{
        "flat_map"    => fn -> Enum.flat_map(list, map_fun) end,
        "map.flatten" =>
          fn -> list |> Enum.map(map_fun) |> List.flatten end
      }, time: 0.01, warmup: 0.005)
    end

    readme_sample_asserts output
  end

  test "integration expanded README example" do
    output = capture_io fn ->
      list = Enum.to_list(1..10_000)
      map_fun = fn(i) -> [i, i * i] end

      Benchee.init(@test_times)
      |> Benchee.system
      |> Benchee.benchmark("flat_map", fn -> Enum.flat_map(list, map_fun) end)
      |> Benchee.benchmark("map.flatten",
                           fn -> list |> Enum.map(map_fun) |> List.flatten end)
      |> Benchee.measure
      |> Benchee.statistics
      |> Benchee.Formatters.Console.format
      |> IO.puts
    end

    readme_sample_asserts(output)
  end

  test "integration super fast function print warnings" do
    output = capture_io fn ->
      Benchee.run(%{"Sleeps" => fn -> 0 end}, time: 0.001, warmup: 0)
    end

    assert output =~ ~r/fast/
    assert output =~ ~r/unreliable/
    assert output =~ ~r/^Sleeps\s+\d+.+\s+0\.\d+ μs/m
  end

  test "integration super fast function warning is printed once per job" do
    output = capture_io fn ->
      Benchee.run(%{"Fast" => fn -> 0 end}, time: 0.001, warmup: 0.001)
    end

    warnings = output
               |> String.split("\n")
               |> Enum.filter(fn(line) -> line =~ ~r/Warning.+fast/ end)

    assert Enum.count(warnings) == 1
  end

  test "integration super fast function warnings can be deactivated" do
    output = capture_io fn ->
      Benchee.run(%{"Blitz" => fn -> 0 end},
                  time: 0.001, warmup: 0, print: [fast_warning: false])
    end

    refute Regex.match? ~r/fast/, output
  end

  test "integration comparison report can be deactivated" do
    output = capture_io fn ->
      Benchee.run(%{"Sleeps"   => fn -> :timer.sleep(10) end,
                    "Sleeps 2" => fn -> :timer.sleep(20) end},
                    time: 0.01,
                    warmup: 0,
                    console: [comparison: false])
    end

    refute output =~ ~r/compar/i
  end

  test "multiple formatters can be configured and are all called" do
    output = capture_io fn ->
      Benchee.run(%{
        "Sleeps" => fn -> :timer.sleep(10) end},
        time:       0.01,
        warmup:     0.01,
        formatters: [fn(_) -> IO.puts "Formatter one" end,
                     fn(_) -> IO.puts "Formatter two" end]
      )
    end

    assert output =~ "Formatter one"
    assert output =~ "Formatter two"
  end

  @rough_10_milli_s "((8|9|10|11|12|13|14)\\.\\d{2} ms)"
  test "formatters have full access to the suite data, values in assigns" do
    retrying fn ->
      formatter_one = fn(suite) ->
        run_time = suite.scenarios
                   |> (fn([scenario | _]) -> List.last(scenario.run_times) end).()
                   |> Benchee.Conversion.Duration.format

        IO.puts "Run time: #{run_time}"
      end

      formatter_two = fn(suite) ->
        average = suite.scenarios
                  |> (fn([scenario | _]) -> scenario.run_time_statistics.average end).()
                  |> Benchee.Conversion.Duration.format
        IO.puts "Average: #{average}"
      end

      formatter_three = fn(suite) ->
        IO.puts suite.configuration.assigns.custom
      end

      output = capture_io fn ->
        Benchee.run(%{"Sleeps" => fn -> :timer.sleep(10) end},
          time:       0.01,
          warmup:     0.005,
          assigns:   %{custom: "Custom value"},
          formatters: [formatter_one, formatter_two, formatter_three]
        )
      end

      assert output =~ ~r/Run time: #{@rough_10_milli_s}$/m
      assert output =~ ~r/Average: #{@rough_10_milli_s}$/m
      assert output =~ "Custom value"
    end
  end

  test "inputs feature version of readme example" do
    output = capture_io fn ->
      map_fun = fn(i) -> [i, i * i] end

      configuration = Keyword.merge @test_times,
                                    inputs: %{"list" => Enum.to_list(1..10_000)}

      Benchee.run(%{
        "flat_map"    => fn(input) -> Enum.flat_map(input, map_fun) end,
        "map.flatten" =>
          fn(input) -> input |> Enum.map(map_fun) |> List.flatten end
      }, configuration)
    end

    readme_sample_asserts(output)
  end

  test "multiple inputs" do
    output = capture_io fn ->
      map_fun = fn(i) -> [i, i * i] end
      inputs = [
        inputs: %{
          "small list"  => Enum.to_list(1..100),
          "medium list" => Enum.to_list(1..1_000),
          "bigger list" => Enum.to_list(1..10_000),
        }
      ]

      configuration = Keyword.merge @test_times, inputs


      Benchee.run(%{
        "flat_map"    => fn(input) -> Enum.flat_map(input, map_fun) end,
        "map.flatten" =>
          fn(input) -> input |> Enum.map(map_fun) |> List.flatten end
      }, configuration)
    end

    assert String.contains? output, ["small list", "medium list", "bigger list"]
    occurences = Regex.scan body_regex("flat_map"), output
    assert length(occurences) == 3
  end

  test "multiple inputs with very fast functions" do
    output = capture_io fn ->
      inputs = [inputs: %{"number_one" => 1, :symbole_one => :one}]

      configuration = Keyword.merge @test_times, inputs

      Benchee.run(%{
        "identity" => fn(i) -> i end
      }, configuration)
    end

    assert Regex.match?(@header_regex, output)
    assert Regex.match? ~r/fast/, output
    assert Regex.match? ~r/unreliable/, output

    assert String.contains? output, ["number_one", "symbol_one"]
    occurences = Regex.scan body_regex("identity"), output
    assert length(occurences) == 2
  end

  test ".run returns the suite intact" do
    capture_io fn ->
      suite = Benchee.run(%{
        "sleep"    => fn -> :timer.sleep 1 end
      }, time: 0.001, warmup: 0)
      assert %Benchee.Suite{scenarios: _, configuration: _} = suite
    end
  end

  test ".run also adds system information into the mix via Benchee.System" do
    capture_io fn ->
      suite = Benchee.run(%{
        "sleep"    => fn -> :timer.sleep 1 end
      }, time: 0.001, warmup: 0)
      elixir = Benchee.System.elixir
      erlang = Benchee.System.erlang

      assert %{system: %{elixir: ^elixir, erlang: ^erlang}} = suite
    end
  end

  test ".run accepts atom keys for jobs" do
    capture_io fn ->
      suite = Benchee.run(%{
        sleep: fn -> :timer.sleep 1 end
      }, time: 0.001, warmup: 0)

      assert Enum.map(suite.scenarios, &(&1.job_name)) == ~w(sleep)
    end
  end

  test ".run accepts atom keys for inputs" do
    output = capture_io fn ->
      map_fun = fn(i) -> [i, i * i] end
      inputs = [
        inputs: %{
          "small list"  => Enum.to_list(1..100),
          mediumList:      Enum.to_list(1..1_000)
        }
      ]

      configuration = Keyword.merge @test_times, inputs

      Benchee.run(%{
        "flat_map"    => fn(input) -> Enum.flat_map(input, map_fun) end,
        "map.flatten" =>
          fn(input) -> input |> Enum.map(map_fun) |> List.flatten end
      }, configuration)
    end

    assert String.contains? output, ["small list", "mediumList"]
    occurences = Regex.scan body_regex("flat_map"), output
    assert length(occurences) == 2
  end

  describe "hooks" do
    test "it runs all of them" do
      capture_io fn ->
        myself = self()
        Benchee.run %{
          "sleeper"   => {
            fn -> :timer.sleep 1 end,
            before_each: fn -> send myself, :local_before end,
            after_each:  fn -> send myself, :local_after end,
            before_scenario: fn -> send myself, :local_before_scenario end,
            after_scenario: fn -> send myself, :local_after_scenario end},
          "sleeper 2" => fn -> :timer.sleep 1 end
        }, time: 0.0001,
           warmup: 0,
           before_each: fn -> send myself, :global_before end,
           after_each:  fn -> send myself, :global_after end,
           before_scenario: fn -> send myself, :global_before_scenario end,
           after_scenario:  fn -> send myself, :global_after_scenario end
      end

      assert_received_exactly [
        # first job with all those local hooks
        :global_before_scenario, :local_before_scenario, :global_before,
        :local_before, :local_after, :global_after, :local_after_scenario,
        :global_after_scenario,
        # second job that only runs global hooks
        :global_before_scenario, :global_before, :global_after,
        :global_after_scenario
      ]
    end
  end

  @slower_regex "\\s+- \\d+\\.\\d+x slower"
  defp readme_sample_asserts(output) do
    assert output =~ @header_regex
    assert output =~ body_regex("flat_map")
    assert output =~ body_regex("map.flatten")
    assert output =~ ~r/Comparison/, output
    assert output =~ ~r/^map.flatten\s+\d+(\.\d+)?\s*.?(#{@slower_regex})?$/m
    assert output =~ ~r/^flat_map\s+\d+(\.\d+)?\s*.?(#{@slower_regex})?$/m
    assert output =~ ~r/#{@slower_regex}/m

    refute Regex.match?(~r/fast/i, output)
  end

  defp body_regex(benchmark_name) do
    ~r/^#{benchmark_name}\s+\d+.+\s+\d+\.?\d*.+\s+.+\d+\.?\d*.+\s+\d+\.?\d*.+/m
  end
end
