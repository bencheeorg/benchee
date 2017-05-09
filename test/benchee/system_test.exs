defmodule Benchee.SystemTest do
  use ExUnit.Case, async: true

  alias Benchee.Suite

  test ".system adds the content to a given suite" do
    system_info = Benchee.System.system(%Suite{})
    assert %{system: %{elixir: _, erlang: _, num_cores: _, os: _,
                       cpu_speed: _, available_memory: _}} = system_info
  end

  test ".elixir returns the current elixir version" do
    assert Benchee.System.elixir() =~ ~r/\d+\.\d+\.\d+/
  end

  test ".erlang returns the current erlang version in use" do
    version = Benchee.System.erlang()
    assert version =~ to_string(:erlang.system_info(:otp_release))
    assert version =~ ~r/\d+\.\d+/
    refute version =~ "\n"
  end

  test ".num_cores returns the number of cores on the running VM" do
    assert Benchee.System.num_cores() > 0
  end

  test ".os returns an atom of the current os" do
    assert Enum.member?([:Linux, :macOS, :Windows], Benchee.System.os())
  end

  test ".cpu_speed returns the speed of the current cpu" do
    speed = Benchee.System.cpu_speed()
    assert speed =~ ~r/\d+.*hz/i || speed == "N/A"
  end

  test ".available_memory returns the available memory on the computer" do
    memory = Benchee.System.available_memory()
    assert memory > 100_000_000 || memory == "N/A"
  end
end
