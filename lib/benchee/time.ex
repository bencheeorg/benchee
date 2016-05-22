defmodule Benchee.Time do
  @seconds_to_microseconds 1_000_000
  
  def microseconds_to_seconds(microseconds) do
    microseconds / @seconds_to_microseconds
  end

  def seconds_to_microseconds(seconds) do
    seconds * @seconds_to_microseconds
  end
end
