defmodule BencheeTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  doctest Benchee

  @header_regex ~r/^Name.+ips.+average.+deviation.+median$/m
  @test_times   %{time: 0.1, warmup: 0.02}
  test "integration step by step" do
    capture_io fn ->
      result =
        Benchee.init(@test_times)
        |> Benchee.benchmark("Sleeps", fn -> :timer.sleep(10) end)
        |> Benchee.measure
        |> Benchee.Statistics.statistics
        |> Benchee.Formatters.Console.format

      [header, benchmark_stats] = result
      assert Regex.match?(@header_regex, header)
      assert Regex.match?(body_regex("Sleeps"), benchmark_stats)
    end
  end

  test "integration high level interface .run" do
    output = capture_io fn ->
      Benchee.run(@test_times, [{"Sleeps", fn -> :timer.sleep(10) end}])
    end

    assert Regex.match?(@header_regex, output)
    assert Regex.match?(body_regex("Sleeps"), output)
    refute Regex.match? ~r/Compariosn/, output
    refute Regex.match? ~r/x slower/, output
  end

  test "integration multiple funs in .run" do
    output = capture_io fn ->
      Benchee.run(@test_times,
                  [{"Sleeps", fn -> :timer.sleep(10) end},
                   {"Magic", fn -> Enum.to_list(1..100)  end}])
    end

    assert Regex.match?(@header_regex, output)
    assert Regex.match?(body_regex("Sleeps"), output)
    assert Regex.match?(body_regex("Magic"), output)
  end

  test "integration high level README example" do
    output = capture_io fn ->
      list = Enum.to_list(1..10_000)
      map_fun = fn(i) -> [i, i * i] end

      Benchee.run(@test_times,
                   [{"flat_map", fn -> Enum.flat_map(list, map_fun) end},
                    {"map.flatten",
                    fn -> list |> Enum.map(map_fun) |> List.flatten end}])
    end

    readme_sample_asserts(output)
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
      Benchee.run(%{time: 0.01, warmup: 0}, [{"Sleeps", fn -> 0 end}])
    end

    assert Regex.match? ~r/fast/, output
    assert Regex.match? ~r/unreliable/, output
  end

  test "integration super fast function warning is printed once per job" do
    output = capture_io fn ->
      Benchee.run(%{time: 0.01, warmup: 0.01}, [{"Sleeps", fn -> 0 end}])
    end

    warnings = output
               |> String.split("\n")
               |>Enum.filter(fn(line) -> line =~ ~r/fast/ end)

    assert Enum.count(warnings) == 1
  end

  defp readme_sample_asserts(output) do
    assert Regex.match?(@header_regex, output)
    assert Regex.match?(body_regex("flat_map"), output)
    assert Regex.match?(body_regex("map.flatten"), output)
    assert Regex.match?(~r/Comparison/, output)
    assert Regex.match?(~r/^map.flatten\s+\d+\.\d+$/m, output)
    assert Regex.match?(~r/^flat_map\s+\d+\.\d+\s+- \d\.\d+x slower$/m, output)

    refute Regex.match?(~r/fast/i, output)
  end

  defp body_regex(benchmark_name) do
    ~r/^#{benchmark_name}\s+\d+.+\s+\d+\.\d+.+\s+.+\d+\.\d+.+\s+\d+\.\d+.+/m
  end
end
