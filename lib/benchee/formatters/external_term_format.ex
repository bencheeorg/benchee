defmodule Benchee.Formatters.ExternalTermFormat do
  @moduledoc """
  Store the whole suite in the Erlang `ExternalTermFormat` - can be used for
  storing and loading the results of previous runs.
  """

  use Benchee.Formatter

  alias Benchee.Suite

  @spec format(Suite.t) :: {binary, String.t}
  def format(suite = %Suite{configuration: configuration}) do
    file_name = configuration.formatter_options.external_term_format.file

    {:erlang.term_to_binary(suite), file_name}
  end

  @spec write({binary, String.t}) :: :ok | {:error, String.t}
  def write({term_binary, filename}) do
    return_value = File.write(filename, term_binary)

    IO.puts "Suite saved in external term format at #{filename}"

    return_value
  end
end
