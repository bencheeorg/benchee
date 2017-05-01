defmodule Benchee.System do
  @moduledoc """
  Provides information about the system the benchmarks are run on.
  """

  alias Benchee.Suite

  @doc """
  Adds system information to the suite (currently elixir and erlang versions).
  """
  @spec system(Suite.t) :: Suite.t
  def system(suite = %Suite{}) do
    versions = %{elixir: elixir(), erlang: erlang()}
    %Suite{suite | system: versions}
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
      {:ok, version}    -> String.trim(version)
      {:error, reason}  ->
        IO.puts "Error trying to dermine erlang version #{reason}"
    end
  end

end
