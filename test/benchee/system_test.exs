defmodule Benchee.SystemTest do
  use ExUnit.Case, async: true

  alias Benchee.Suite
  import ExUnit.CaptureIO
  import Benchee.System

  test ".system adds the content to a given suite" do
    system_info = system(%Suite{})

    assert %{
             system: %{
               elixir: _,
               erlang: _,
               num_cores: _,
               os: _,
               cpu_speed: _,
               available_memory: _
             }
           } = system_info
  end

  test ".elixir returns the current elixir version" do
    assert system(%Suite{}).system.elixir =~ ~r/\d+\.\d+\.\d+/
  end

  test ".erlang returns the current erlang version in use" do
    version = system(%Suite{}).system.erlang
    assert version =~ to_string(:erlang.system_info(:otp_release))
    assert version =~ ~r/\d+\.\d+/
    refute version =~ "\n"
  end

  test ".num_cores returns the number of cores on the running VM" do
    assert system(%Suite{}).system.num_cores > 0
  end

  test ".os returns an atom of the current os" do
    assert Enum.member?([:Linux, :FreeBSD, :macOS, :Windows], system(%Suite{}).system.os)
  end

  test ".cpu_speed returns a string (more accurate tests in .parse_cpu_for)" do
    assert "" <> _actual_content = system(%Suite{}).system.cpu_speed
  end

  describe ".parse_cpu_for" do
    @cat_proc_cpu_info_excerpt """
    processor	: 0
    vendor_id	: GenuineIntel
    cpu family	: 6
    model		: 60
    model name	: Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz
    stepping	: 3
    """
    test "for :Linux handles some normal intel output" do
      output = parse_cpu_for(:Linux, @cat_proc_cpu_info_excerpt)
      assert output =~ "Intel(R) Core(TM) i7-4790 CPU @ 3.60GHz"
    end

    test "for :Linux handles Semaphore CI output" do
      semaphore_output = "model name	: Intel Core Processor (Haswell)"
      output = parse_cpu_for(:Linux, semaphore_output)
      assert output =~ "Haswell"
    end

    test "for :Linux handles unknown architectures" do
      raw_output = "Bender Bending Rodriguez"
      output = parse_cpu_for(:Linux, raw_output)
      assert output == "Unrecognized processor"
    end
  end

  test ".available_memory returns the available memory on the computer" do
    {num, rest} = Float.parse(system(%Suite{}).system.available_memory)

    decimal_part_of_available_memory =
      "#{num}"
      |> String.split(".")
      |> Enum.at(1)
      |> String.length()

    assert num > 0
    assert decimal_part_of_available_memory <= 2
    assert rest =~ ~r/GB/
  end

  test ".system_cmd handles errors gracefully" do
    system_func = fn _, _ -> {"ERROR", 1} end

    captured_io =
      capture_io(fn ->
        system_cmd("cat", "dev/null", system_func)
      end)

    assert captured_io =~ "Something went wrong"
    assert captured_io =~ "ERROR"

    capture_io(fn ->
      assert system_cmd("cat", "dev/null", system_func) == "N/A"
    end)
  end
end
