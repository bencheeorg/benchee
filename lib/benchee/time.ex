defmodule Benchee.Time do
  @moduledoc """
  Simple time conversions.
  """

  @seconds_to_microseconds 1_000_000

  @doc """
  Converts microseconds to seconds.

  ## Examples

      iex> Benchee.Time.microseconds_to_seconds(1_234_000)
      1.234

  """
  def microseconds_to_seconds(microseconds) do
    microseconds / @seconds_to_microseconds
  end

  @doc """
  Converts seconds to microseconds.

  ## Examples

      iex> Benchee.Time.seconds_to_microseconds(1.234)
      1_234_000.0

  """
  def seconds_to_microseconds(seconds) do
    seconds * @seconds_to_microseconds
  end
end
