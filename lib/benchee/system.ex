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
    system_info = %{elixir: elixir(), erlang: erlang(), num_cores: num_cores(),
                    os: os(), available_memory: available_memory(),
                    cpu_speed: cpu_speed()}
    %Suite{suite | system: system_info}
  end

  @doc """
  Returns current Elixir version in use.
  """
  def elixir, do: System.version()

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

  def num_cores do
    System.schedulers_online()
  end

  def os do
    {_, name} = :os.type()
    os(name)
  end

  defp os(:darwin), do: :macOS
  defp os(:nt), do: :Windows
  defp os(_), do: :Linux

  def cpu_speed do
    cpu_speed(os())
  end

  defp cpu_speed(:macOS) do
    {output, exit_code} = System.cmd("sysctl", ["-n", "machdep.cpu.brand_string"])
    if exit_code > 0 do
      IO.puts("Something went wrong trying to get system information")
    end
    output
  end
  defp cpu_speed(:Windows) do
    "N/A"
  end
  defp cpu_speed(:Linux) do
    "N/A"
  end

  def available_memory do
    available_memory(os())
  end

  defp available_memory(:macOS) do
    {output, exit_code} = System.cmd("sysctl", ["-n", "hw.memsize"])
    if exit_code > 0 do
      IO.puts("Something went wrong trying to get system information")
    end
    output
  end
  defp available_memory(:Windows) do
    "N/A"
  end
  defp available_memory(:Linux) do
    "N/A"
  end
end
