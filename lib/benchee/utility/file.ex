defmodule Benchee.Utility.File do
  @moduledoc """
  Methods to create files used in plugins.
  """

  @doc """
  Open a file for write for all inputs and calls function with file and content.

  Uses `Benchee.Utility.File.interlave/2` to get the base filename and the
  given inputs together to one nice file name, then creates these files and
  calls the function with the file and the content from the given map so that
  data can be written to the file.

  Expects:

  * inputs_to_content - a map from input name to contents that should go into
  the corresponding file
  * filename - the base file name as desired by the user
  * function - a function that is then called for every file with the associated
  file content from the map

  ## Examples

      # Just writes the contents to a file
      Benchee.Utility.File.each_input(%{"My Input" => "_awesome html content_"},
        "my.html",
        fn(file, content) -> IO.write(file, content) end)
  """
  def each_input(inputs_to_content, filename, function) do
    Enum.each inputs_to_content, fn({input_name, content}) ->
      input_filename = interleave(filename, input_name)
      File.open input_filename, [:write], fn(file) ->
        function.(file, content)
      end
    end
  end

  @doc """
  Gets file name/path and the input name together.

  Handles the special no_input key to do no work at all.

  ## Examples

      iex> Benchee.Utility.File.interleave("abc.csv", "hello")
      "abc_hello.csv"

      iex> Benchee.Utility.File.interleave("abc.csv", "Big Input")
      "abc_big_input.csv"

      iex> Benchee.Utility.File.interleave("bench/abc.csv", "Big Input")
      "bench/abc_big_input.csv"

      iex> marker = Benchee.Benchmark.no_input
      iex> Benchee.Utility.File.interleave("abc.csv", marker)
      "abc.csv"
  """
  def interleave(filename, input) do
    Path.rootname(filename) <> to_filename(input) <> Path.extname(filename)
  end

  defp to_filename(input_string) do
    no_input = Benchee.Benchmark.no_input
    case input_string do
      ^no_input -> ""
      _         ->
        String.downcase("_" <> String.replace(input_string, " ", "_"))
    end
  end
end
