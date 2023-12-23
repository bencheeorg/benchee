defmodule Benchee.SystemTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO
  import Benchee.System

  alias Benchee.Suite
  alias Benchee.System
  alias Benchee.Utility.ErlangVersion

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
    assert Enum.member?(
             [:Linux, :Solaris, :FreeBSD, :macOS, :Windows],
             system(%Suite{}).system.os
           )
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

    @solaris_kstat_brand_excerpt """
    cpu_info:0:cpu_info0:brand      Intel(r) Xeon(r) CPU E5-2678 v3 @ 2.50GHz
    """
    test "for :Solaris handles some normal intel output" do
      output = parse_cpu_for(:Solaris, @solaris_kstat_brand_excerpt)
      assert output =~ "Intel(r) Xeon(r) CPU E5-2678 v3 @ 2.50GHz"
    end

    test "for :Solaris handles unknown architectures" do
      raw_output = "Bender Bending Rodriguez"
      output = parse_cpu_for(:Solaris, raw_output)
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

  describe "all_protocols_consolidated?/1" do
    test "normally it just works and is true for Bechee and does not log a warning" do
      warning =
        capture_io(fn ->
          assert true == all_protocols_consolidated?()
        end)

      assert warning == ""
    end

    test "when it borks out it warns and defaults to true, see #384" do
      fake_lib_dir = fn _, _ -> {:error, :bad_name} end

      warning =
        capture_io(fn ->
          assert true == all_protocols_consolidated?(fake_lib_dir)
        end)

      assert warning =~ ~r/not.*check.*protocol.*consolidat/i
    end
  end

  # It may be compiled in a way that it doesn't but in the CI and dev machines it should be fine
  test ".jit_enabled? should say true for versions > 24.0.0" do
    system_data = system(%Suite{}).system
    jit_enabled? = system_data.jit_enabled?
    erlang_version = system_data.erlang

    if ErlangVersion.includes_fixes_from?(erlang_version, "24.0.0") do
      assert jit_enabled?
    else
      refute jit_enabled?
    end
  end

  @system %System{
    elixir: "1.4.0",
    erlang: "19.1",
    jit_enabled?: false,
    num_cores: "4",
    os: "Super Duper",
    available_memory: "8 Trillion",
    cpu_speed: "light speed"
  }
  describe "deep_merge behaviour" do
    test "it merges with a map preserving other keys" do
      assert %{elixir: "1.15.7", erlang: "19.1"} =
               DeepMerge.deep_merge(@system, %{elixir: "1.15.7"})
    end
  end
end
