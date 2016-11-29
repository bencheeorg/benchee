defmodule Benchee.SystemTest do
  use ExUnit.Case, async: true

  test ".system adds the content to a given suite" do
    assert %{system: %{elixir: _, erlang: _}} = Benchee.System.system(%{})
  end

  test ".elixir returns the current elixir version" do
    assert Benchee.System.elixir =~ ~r/\d+\.\d+\.\d+/
  end

  test ".erlang returns the current erlang version in use" do
    version = Benchee.System.erlang
    assert version =~ to_string(:erlang.system_info(:otp_release))
    assert version =~ ~r/\d+\.\d+/
    refute version =~ "\n"
  end
end
