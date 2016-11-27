defmodule Benchee.Utility.File do
  @moduledoc """
  Methods to create files used in plugins.
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
