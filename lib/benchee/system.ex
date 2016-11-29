defmodule Benchee.System do
  @moduledoc """
  Provides information about the system the benchmarks are run on.
  """

  @doc """
  Adds system information to the suite (currently elixir and erlang versions).
  """
  def system(suite) do
    versions = %{elixir: elixir(), erlang: erlang()}
    Map.put suite, :system, versions
  end

  @doc """
  Returns current Elixir version in use.
  """
  def elixir, do: System.version

  @doc """
  Returns the current erlang/otp version in use.
  """
  def erlang do
    otp_release = :erlang.system_info(:otp_release)
    file = Path.join([:code.root_dir, "releases", otp_release , "OTP_VERSION"])
    case File.read(file) do
      {:ok, version}    -> String.strip(version)
      {:error, reason}  ->
        IO.puts "Error trying to dermine erlang version #{reason}"
    end
  end

end
