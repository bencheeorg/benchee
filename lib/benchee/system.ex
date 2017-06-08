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
    system_info = %{elixir: elixir(),
                    erlang: erlang(),
                    num_cores: num_cores(),
                    os: os(),
                    available_memory: available_memory(),
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

  @doc """
  Returns the number of cores available for the currently running VM.
  """
  def num_cores do
    System.schedulers_online()
  end

  @doc """
  Returns an atom representing the platform the VM is running on.
  """
  def os do
    {_, name} = :os.type()
    os(name)
  end
  defp os(:darwin), do: :macOS
  defp os(:nt), do: :Windows
  defp os(_), do: :Linux

  @doc """
  Returns a string with detailed information about the CPU the benchmarks are
  being performed on.
  """
  def cpu_speed, do: cpu_speed(os())

  defp cpu_speed(:Windows) do
    parse_cpu_for(:Windows, system_cmd("WMIC", ["CPU", "GET", "NAME"]))
  end
  defp cpu_speed(:macOS) do
    parse_cpu_for(:macOS, system_cmd("sysctl", ["-n", "machdep.cpu.brand_string"]))
  end
  defp cpu_speed(:Linux) do
    parse_cpu_for(:Linux, system_cmd("cat", ["/proc/cpuinfo"]))
  end

  def parse_cpu_for(_, "N/A"), do: "N/A"
  def parse_cpu_for(:Windows, raw_output) do
    "Name" <> cpu_info = raw_output
    String.trim(cpu_info)
  end
  def parse_cpu_for(:macOS, raw_output), do: String.trim(raw_output)
  def parse_cpu_for(:Linux, raw_output) do
    ["model name\t:" <> cpu_info] = Regex.run(~r/model name.*:[\w \(\)\-\@\.]*ghz/i, raw_output)
    String.trim(cpu_info)
  end

  @doc """
  Returns an integer with the total number of available memory on the machine
  running the benchmarks.
  """
  @byte_to_gigabyte 1024 * 1024 * 1024
  def available_memory do
    {:ok, pid} = :memsup.start_link()

    # see: http://erlang.org/doc/man/memsup.html#get_system_memory_data-0
    # we use total_memory not the system one as what's really interesting is
    # what is available to the Erlang VM not the system as a whole.
    total_memory_giga_byte = :memsup.get_system_memory_data()
                             |> Keyword.get(:total_memory)
                             |> Kernel./(@byte_to_gigabyte)

    # Feels like I tried a lot of things for the exiting to stop printing messsages
    # :error_logger.tty(false); capture_io, capture_io with :stderr, starting os_mon
    # myself
    # might as well be I did a mistake...
    Process.unlink(pid)
    Process.exit(pid, :normal) # kill right here to avoid annoying messages in the end
    "#{total_memory_giga_byte} GB"
  end

  def system_cmd(cmd, args, system_func \\ &System.cmd/2) do
    {output, exit_code} = system_func.(cmd, args)
    if exit_code > 0 do
      IO.puts("Something went wrong trying to get system information:")
      IO.puts(output)
      "N/A"
    else
      output
    end
  end
end
