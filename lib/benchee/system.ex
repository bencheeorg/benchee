defmodule Benchee.System do
  @moduledoc """
  Provides information about the system the benchmarks are run on.

  Includes information such as elixir/erlang version, OS, CPU and memory.

  So far supports/should work for Linux, MacOS, FreeBSD, Solaris and Windows.
  """

  alias Benchee.Conversion.Memory
  alias Benchee.Suite
  alias Benchee.Utility.ErlangVersion

  @enforce_keys [
    :elixir,
    :erlang,
    :jit_enabled?,
    :num_cores,
    :os,
    :available_memory,
    :cpu_speed
  ]

  defstruct [
    :elixir,
    :erlang,
    :jit_enabled?,
    :num_cores,
    :os,
    :available_memory,
    :cpu_speed
  ]

  @type t :: %__MODULE__{
          elixir: String.t(),
          erlang: String.t(),
          jit_enabled?: boolean(),
          num_cores: pos_integer(),
          os: :macOS | :Windows | :FreeBSD | :Solaris | :Linux,
          cpu_speed: String.t(),
          available_memory: String.t()
        }

  @doc """
  Adds system information to the suite (currently elixir and erlang versions).
  """
  @spec system(Suite.t()) :: Suite.t()
  def system(suite = %Suite{}) do
    erlang_version = erlang()

    system_info = %__MODULE__{
      elixir: elixir(),
      erlang: erlang_version,
      jit_enabled?: jit_enabled?(erlang_version),
      num_cores: num_cores(),
      os: os(),
      available_memory: available_memory(),
      cpu_speed: cpu_speed()
    }

    warn_about_performance_degrading_settings()

    %Suite{suite | system: system_info}
  end

  defp erlang do
    otp_release = :erlang.system_info(:otp_release)
    file = Path.join([:code.root_dir(), "releases", otp_release, "OTP_VERSION"])

    case File.read(file) do
      {:ok, version} ->
        String.trim(version)

      # Livebook seemingly doesn't have the file where we expect it to be:
      # https://github.com/bencheeorg/benchee/issues/367
      {:error, reason} ->
        IO.puts(
          "Error trying to determine erlang version #{reason}, falling back to overall OTP version"
        )

        to_string(otp_release)
    end
  end

  defp elixir, do: System.version()

  @first_jit_version "24.0.0"
  defp jit_enabled?(erlang_version) do
    if ErlangVersion.includes_fixes_from?(erlang_version, @first_jit_version) do
      :erlang.system_info(:emu_flavor) == :jit
    else
      false
    end
  end

  defp num_cores do
    System.schedulers_online()
  end

  defp os do
    {_, name} = :os.type()
    os(name)
  end

  defp os(:darwin), do: :macOS
  defp os(:nt), do: :Windows
  defp os(:freebsd), do: :FreeBSD
  defp os(:sunos), do: :Solaris
  defp os(_), do: :Linux

  defp cpu_speed, do: cpu_speed(os())

  defp cpu_speed(:Windows) do
    parse_cpu_for(:Windows, system_cmd("WMIC", ["CPU", "GET", "NAME"]))
  end

  defp cpu_speed(:macOS) do
    parse_cpu_for(:macOS, system_cmd("sysctl", ["-n", "machdep.cpu.brand_string"]))
  end

  defp cpu_speed(:FreeBSD) do
    parse_cpu_for(:FreeBSD, system_cmd("sysctl", ["-n", "hw.model"]))
  end

  defp cpu_speed(:Solaris) do
    parse_cpu_for(:Solaris, system_cmd("kstat", ["-p", "cpu_info:0::brand"]))
  end

  defp cpu_speed(:Linux) do
    parse_cpu_for(:Linux, system_cmd("cat", ["/proc/cpuinfo"]))
  end

  @linux_cpuinfo_regex ~r/model name.*:([\w \(\)\-\@\.]*)/i
  @solaris_cpubrand_regex ~r/^cpu_info:0:cpu_info0:brand\s+(.*)\s*$/i

  @doc false
  def parse_cpu_for(_, "N/A"), do: "N/A"

  def parse_cpu_for(:Windows, raw_output) do
    "Name" <> cpu_info = raw_output
    String.trim(cpu_info)
  end

  def parse_cpu_for(:macOS, raw_output), do: String.trim(raw_output)

  def parse_cpu_for(:FreeBSD, raw_output), do: String.trim(raw_output)

  def parse_cpu_for(:Solaris, raw_output) do
    match_info = Regex.run(@solaris_cpubrand_regex, raw_output, capture: :all_but_first)

    case match_info do
      [cpu_info] -> cpu_info
      _ -> "Unrecognized processor"
    end
  end

  def parse_cpu_for(:Linux, raw_output) do
    match_info = Regex.run(@linux_cpuinfo_regex, raw_output, capture: :all_but_first)

    case match_info do
      [cpu_info] -> String.trim(cpu_info)
      _ -> "Unrecognized processor"
    end
  end

  defp available_memory, do: available_memory(os())

  defp available_memory(:Windows) do
    parse_memory_for(
      :Windows,
      system_cmd("WMIC", ["COMPUTERSYSTEM", "GET", "TOTALPHYSICALMEMORY"])
    )
  end

  defp available_memory(:macOS) do
    parse_memory_for(:macOS, system_cmd("sysctl", ["-n", "hw.memsize"]))
  end

  defp available_memory(:FreeBSD) do
    parse_memory_for(:FreeBSD, system_cmd("sysctl", ["-n", "hw.physmem"]))
  end

  defp available_memory(:Solaris) do
    parse_memory_for(:Solaris, system_cmd("prtconf", ["-m"]))
  end

  defp available_memory(:Linux) do
    parse_memory_for(:Linux, system_cmd("cat", ["/proc/meminfo"]))
  end

  defp parse_memory_for(_, "N/A"), do: "N/A"

  defp parse_memory_for(:Windows, raw_output) do
    [memory] = Regex.run(~r/\d+/, raw_output)
    {memory, _} = Integer.parse(memory)
    Memory.format(memory)
  end

  defp parse_memory_for(:macOS, raw_output) do
    {memory, _} = Integer.parse(raw_output)
    Memory.format(memory)
  end

  defp parse_memory_for(:FreeBSD, raw_output) do
    {memory, _} = Integer.parse(raw_output)
    Memory.format(memory)
  end

  defp parse_memory_for(:Solaris, raw_output) do
    {memory_in_megabytes, _} = Integer.parse(raw_output)
    {memory_in_bytes, _} = Memory.convert({memory_in_megabytes, :megabyte}, :byte)
    Memory.format(memory_in_bytes)
  end

  defp parse_memory_for(:Linux, raw_output) do
    ["MemTotal:" <> memory_info] = Regex.run(~r/MemTotal.*kB/, raw_output)

    {memory_in_kilobytes, _} =
      memory_info
      |> String.trim()
      |> String.trim_trailing(" kB")
      |> Integer.parse()

    {memory_in_bytes, _} =
      Memory.convert(
        {memory_in_kilobytes, :kilobyte},
        :byte
      )

    Memory.format(memory_in_bytes)
  end

  @doc false
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

  defp warn_about_performance_degrading_settings do
    unless all_protocols_consolidated?() do
      IO.puts("""
      Not all of your protocols have been consolidated. In order to achieve the
      best possible accuracy for benchmarks, please ensure protocol
      consolidation is enabled in your benchmarking environment.
      """)
    end
  end

  # just made public for easy testing purposes
  @doc false
  def all_protocols_consolidated?(lib_dir_fun \\ &:code.lib_dir/2) do
    case lib_dir_fun.(:elixir, :ebin) do
      # do we get a good old erlang charlist?
      path when is_list(path) ->
        [path]
        |> Protocol.extract_protocols()
        |> Enum.all?(&Protocol.consolidated?/1)

      _error ->
        IO.puts(
          "Could not check if protocols are consolidated. Running as escript? Defaulting to they are consolidated."
        )

        true
    end
  end
end

defimpl DeepMerge.Resolver, for: Benchee.System do
  def resolve(original, override = %Benchee.System{}, resolver) do
    Map.merge(original, override, resolver)
  end

  def resolve(original, override, resolver) when is_map(override) do
    Map.merge(original, override, resolver)
  end
end
