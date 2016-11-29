defmodule Benchee.Utility.FileCreation do
  @moduledoc """
  Methods to create files used in plugins.
  """

  @doc """
  Open a file for write for all key/value pairs, interleaves the file name and
  calls function with file, content and filename.

  Uses `Benchee.Utility.FileCreation.interlave/2` to get the base filename and
  the given keys together to one nice file name, then creates these files and
  calls the function with the file and the content from the given map so that
  data can be written to the file.

  If a directory is specified, it creates the directory.

  Expects:

  * names_to_content - a map from input name to contents that should go into
  the corresponding file
  * filename - the base file name as desired by the user
  * function - a function that is then called for every file with the associated
  file content from the map

  ## Examples

      # Just writes the contents to a file
      Benchee.Utility.FileCreation.each(%{"My Input" => "_awesome html content_"},
        "my.html",
        fn(file, content) -> IO.write(file, content) end)
  """
  def each(names_to_content, filename, function \\ &default_each/3) do
    create_directory filename
    Enum.each names_to_content, fn({input_name, content}) ->
      input_filename = interleave(filename, input_name)
      File.open input_filename, [:write, :utf8], fn(file) ->
        function.(file, content, input_filename)
      end
    end
  end

  defp default_each(file, content, input_filename) do
    :ok = IO.write file, content
    IO.puts "Generated #{input_filename}"
  end

  defp create_directory(filename) do
    directory = Path.dirname filename
    File.mkdir_p! directory
  end

  @doc """
  Gets file name/path and the input name together.

  Handles the special no_input key to do no work at all.

  ## Examples

      iex> Benchee.Utility.FileCreation.interleave("abc.csv", "hello")
      "abc_hello.csv"

      iex> Benchee.Utility.FileCreation.interleave("abc.csv", "Big Input")
      "abc_big_input.csv"

      iex> Benchee.Utility.FileCreation.interleave("bench/abc.csv", "Big Input")
      "bench/abc_big_input.csv"

      iex> marker = Benchee.Benchmark.no_input
      iex> Benchee.Utility.FileCreation.interleave("abc.csv", marker)
      "abc.csv"
  """
  def interleave(filename, name) do
    Path.rootname(filename) <> to_filename(name) <> Path.extname(filename)
  end

  defp to_filename(name_string) do
    no_input = Benchee.Benchmark.no_input
    case name_string do
      ^no_input -> ""
      _         ->
        String.downcase("_" <> String.replace(name_string, " ", "_"))
    end
  end
end
