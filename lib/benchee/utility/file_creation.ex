defmodule Benchee.Utility.FileCreation do
  @moduledoc """
  Methods to easily handle file creation used in plugins.
  """

  alias Benchee.Benchmark

  @doc """
  Open a file for write for all key/value pairs, interleaves the file name with
  the key and calls the given function with file, content and filename.

  Uses `interleave/2` to get the base filename and
  the given keys together to one nice file name, then creates these files and
  calls the function with the file and the content from the given map so that
  data can be written to the file.

  If a directory is specified, it creates the directory.

  Expects:

  * names_to_content - a map from input name to contents that should go into
  the corresponding file
  * filename - the base file name as desired by the user
  * function - a function that is then called for every file with the associated
  file content from the map, defaults to just writing the file content via
  `IO.write/2` and printing where it put the file.

  ## Examples

      # Just writes the contents to a file
      Benchee.Utility.FileCreation.each(%{"My Input" => "_awesome html content_"},
        "my.html",
        fn(file, content) -> IO.write(file, content) end)
  """
  def each(names_to_content, filename, function \\ &default_each/3) do
    ensure_directory_exists(filename)

    Enum.each(names_to_content, fn {input_name, content} ->
      input_filename = interleave(filename, input_name)

      File.open!(input_filename, [:write, :utf8], fn file ->
        function.(file, content, input_filename)
      end)
    end)
  end

  defp default_each(file, content, input_filename) do
    :ok = IO.write(file, content)
    IO.puts("Generated #{input_filename}")
  end

  @doc """
  Make sure the directory for the given file name exists.
  """
  def ensure_directory_exists(filename) do
    directory = Path.dirname(filename)
    File.mkdir_p!(directory)
  end

  @doc """
  Gets file name/path, the input name and others together.

  Takes a list of values to interleave or just a single value.
  Handles the special no_input key to do no work at all.

  ## Examples

      iex> Benchee.Utility.FileCreation.interleave("abc.csv", "hello")
      "abc_hello.csv"

      iex> Benchee.Utility.FileCreation.interleave("abc.csv", "Big Input")
      "abc_big_input.csv"

      iex> Benchee.Utility.FileCreation.interleave("abc.csv", "String.length/1")
      "abc_string_length_1.csv"

      iex> Benchee.Utility.FileCreation.interleave("bench/abc.csv", "Big Input")
      "bench/abc_big_input.csv"

      iex> Benchee.Utility.FileCreation.interleave("bench/abc.csv",
      ...>   ["Big Input"])
      "bench/abc_big_input.csv"

      iex> Benchee.Utility.FileCreation.interleave("abc.csv", [])
      "abc.csv"

      iex> Benchee.Utility.FileCreation.interleave("bench/abc.csv",
      ...>   ["Big Input", "Comparison"])
      "bench/abc_big_input_comparison.csv"

      iex> Benchee.Utility.FileCreation.interleave("bench/A B C.csv",
      ...>   ["Big Input", "Comparison"])
      "bench/A B C_big_input_comparison.csv"

      iex> Benchee.Utility.FileCreation.interleave("bench/abc.csv",
      ...>   ["Big Input", "Comparison", "great Stuff"])
      "bench/abc_big_input_comparison_great_stuff.csv"

      iex> marker = Benchee.Benchmark.no_input
      iex> Benchee.Utility.FileCreation.interleave("abc.csv", marker)
      "abc.csv"
      iex> Benchee.Utility.FileCreation.interleave("abc.csv", [marker])
      "abc.csv"
      iex> Benchee.Utility.FileCreation.interleave("abc.csv",
      ...>   [marker, "Comparison"])
      "abc_comparison.csv"
      iex> Benchee.Utility.FileCreation.interleave("abc.csv",
      ...>   ["Something cool", marker, "Comparison"])
      "abc_something_cool_comparison.csv"
  """
  def interleave(filename, names) when is_list(names) do
    file_names =
      names
      |> Enum.map(&to_filename/1)
      |> prepend(Path.rootname(filename))
      |> Enum.reject(fn string -> String.length(string) < 1 end)
      |> Enum.join("_")

    file_names <> Path.extname(filename)
  end

  def interleave(filename, name) do
    interleave(filename, [name])
  end

  defp prepend(list, item) do
    [item | list]
  end

  defp to_filename(name_string) do
    no_input = Benchmark.no_input()

    case name_string do
      ^no_input ->
        ""

      _ ->
        String.downcase(String.replace(name_string, ~r/[^0-9A-Z]/i, "_"))
    end
  end
end
