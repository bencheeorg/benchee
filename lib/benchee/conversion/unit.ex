defmodule Benchee.Conversion.Unit do
  defstruct [:magnitude, :short, :long]

  alias Benchee.Conversion.Unit

  def scale(value, %Unit{magnitude: magnitude}) do
    value / magnitude
  end
end
