defmodule Benchee.Formatters.ExternalTermFormat do
  @moduledoc """
  Store the whole suite in the Erlang `ExternalTermFormat` - can be used for
  storing and loading the results of previous runs.
  """

  use Benchee.Formatter

  alias Benchee.Suite
  alias Benchee.Utility.FileCreation

  @spec format(Suite.t) :: {binary, String.t}
  def format(suite = %Suite{configuration: configuration}) do
    file_name = configuration.formatter_options.external_term_format.file

    {:erlang.term_to_binary(suite), file_name}
  end

  @spec write({binary, String.t}) :: :ok
  def write({term_binary, filename}) do
    FileCreation.ensure_directory_exists(filename)
    return_value = File.write(filename, term_binary)

    IO.puts "Suite saved in external term format at #{filename}"

    return_value
  end
end
