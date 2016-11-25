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

  test "integration expanded README example" do
    output = capture_io fn ->
      list = Enum.to_list(1..10_000)
      map_fun = fn(i) -> [i, i * i] end

      Benchee.init(@test_times)
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

    assert Regex.match? ~r/fast/, output
    assert Regex.match? ~r/unreliable/, output
  end

  test "integration super fast function warning is printed once per job" do
    output = capture_io fn ->
      Benchee.run(%{"Fast" => fn -> 0 end}, time: 0.001, warmup: 0.001)
    end

    warnings = output
               |> String.split("\n")
               |> Enum.filter(fn(line) -> line =~ ~r/fast/ end)

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

  @rough_10_milli_s "((9|10|11|12|13)\\.\\d{2} ms)"
  test "formatters have full access to the suite data" do
    output = capture_io fn ->
      Benchee.run(%{"Sleeps" => fn -> :timer.sleep(10) end},
        time:       0.01,
        warmup:     0.005,
        custom:     "Custom value",
        formatters: [
          fn(suite) ->
            run_time = suite.run_times
                       |> no_input_access
                       |> Map.get("Sleeps")
                       |> List.last
                       |> Benchee.Conversion.Duration.format

            IO.puts "Run time: #{run_time}"
          end,
          fn(suite) ->
            average = suite.statistics
                      |> no_input_access
                      |> Map.get("Sleeps")
                      |> Map.get(:average)
                      |> Benchee.Conversion.Duration.format
            IO.puts "Average: #{average}"
          end,
          fn(suite) -> IO.puts suite.config.custom end
        ]
      )
    end

    assert output =~ ~r/Run time: #{@rough_10_milli_s}$/m
    assert output =~ ~r/Average: #{@rough_10_milli_s}$/m
    assert output =~ "Custom value"
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

  @slower_regex "\\s+- \\d\\.\\d+x slower"
  defp readme_sample_asserts(output) do
    assert output =~ @header_regex
    assert output =~ body_regex("flat_map")
    assert output =~ body_regex("map.flatten")
    assert output =~ ~r/Comparison/, output
    assert output =~ ~r/^map.flatten\s+\d+\.\d+\s*.?(#{@slower_regex})?$/m
    assert output =~ ~r/^flat_map\s+\d+\.\d+\s*.?(#{@slower_regex})?$/m
    assert output =~ ~r/#{@slower_regex}/m

    refute Regex.match?(~r/fast/i, output)
  end

  defp body_regex(benchmark_name) do
    ~r/^#{benchmark_name}\s+\d+.+\s+\d+\.\d+.+\s+.+\d+\.\d+.+\s+\d+\.\d+.+/m
  end
end
