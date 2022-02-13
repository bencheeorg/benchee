defmodule Benchee.Utility.ErlangVersion do
  @moduledoc false

  # Internal module to deal with erlang version parsing oddity

  @doc """
  Was the given version before the reference version?

  Used to check if a bugfix has already landed.

  Applies some manual massaging, as erlang likes to report versios number not compatible with
  SemVer. If we can't parse the version, to minimize false positives, we assume it's newer.

  Only the `version_to_check` is treated loosely. `version_to_check` must be SemVer compatible,
  as it is assumed to be provided by project maintainers.

  ## Examples

      iex> Benchee.Utility.ErlangVersion.includes_fixes_from?("22.0.0", "22.0.0")
      true

      iex> Benchee.Utility.ErlangVersion.includes_fixes_from?("22.0.1", "22.0.0")
      true

      iex> Benchee.Utility.ErlangVersion.includes_fixes_from?("22.0.0", "22.0.1")
      false

      iex> Benchee.Utility.ErlangVersion.includes_fixes_from?("22.0.4", "22.0.5")
      false

      iex> Benchee.Utility.ErlangVersion.includes_fixes_from?("22.0.4", "22.0.4")
      true

      iex> Benchee.Utility.ErlangVersion.includes_fixes_from?("22.0.5", "22.0.4")
      true

      iex> Benchee.Utility.ErlangVersion.includes_fixes_from?("21.999.9999", "22.0.0")
      false

      iex> Benchee.Utility.ErlangVersion.includes_fixes_from?("23.0.0", "22.0.0")
      true

      # weird longer version numbers work
      iex> Benchee.Utility.ErlangVersion.includes_fixes_from?("22.0.0.0", "22.0.0")
      true

      iex> Benchee.Utility.ErlangVersion.includes_fixes_from?("22.0.0.14", "22.0.0")
      true

      iex> Benchee.Utility.ErlangVersion.includes_fixes_from?("23.3.5.14", "22.0.0")
      true

      iex> Benchee.Utility.ErlangVersion.includes_fixes_from?("21.3.5.14", "22.0.0")
      false

      # weird shorter version numbers work
      iex> Benchee.Utility.ErlangVersion.includes_fixes_from?("22.0", "22.0.0")
      true

      iex> Benchee.Utility.ErlangVersion.includes_fixes_from?("22.0", "22.0.1")
      false

      iex> Benchee.Utility.ErlangVersion.includes_fixes_from?("22.1", "22.0.0")
      true

      iex> Benchee.Utility.ErlangVersion.includes_fixes_from?("21.3", "22.0.0")
      false

      # rc version numbers work
      iex> Benchee.Utility.ErlangVersion.includes_fixes_from?("22.0-rc3", "22.0.0")
      false
      iex> Benchee.Utility.ErlangVersion.includes_fixes_from?("23.0-rc0", "22.0.0")
      true

      # completely broken versions are assumed to be good to avoid false positives
      # as this is not a main functionality but code to potentially work around an older erlang
      # bug.
      iex> Benchee.Utility.ErlangVersion.includes_fixes_from?("super erlang", "22.0.0")
      true
      iex> Benchee.Utility.ErlangVersion.includes_fixes_from?("", "22.0.0")
      true
  """
  def includes_fixes_from?(version_to_check, reference_version) do
    erlang_version = parse_erlang_version(version_to_check)

    case erlang_version do
      {:ok, version} -> Version.compare(version, reference_version) != :lt
      # we do not know which version this is, so don't trust it?
      _ -> true
    end
  end

  # `Version` only supports full SemVer, Erlang loves version numbers like `22.3.4.24` or `22.0`
  # which makes `Version` error out so we gotta manually alter them so that it's `22.3.4`
  @last_version_segment ~r/\.\d+$/
  defp parse_erlang_version(erlang_version) do
    # dot count is a heuristic but it should work
    dot_count =
      erlang_version
      |> String.graphemes()
      |> Enum.count(&(&1 == "."))

    version =
      case dot_count do
        3 -> Regex.replace(@last_version_segment, erlang_version, "")
        1 -> deal_with_major_minor(erlang_version)
        _ -> erlang_version
      end

    Version.parse(version)
  end

  # Only major/minor seem to get the rc treatment
  # but if it is major/minor/patch `Version` handles it correctly.
  # For the 4 digit versions we don't really care right now/normally does not happen.
  defp deal_with_major_minor(erlang_version) do
    # -rc and other weird versions contain -
    if String.contains?(erlang_version, "-") do
      String.replace(erlang_version, "-", ".0-")
    else
      "#{erlang_version}.0"
    end
  end
end
