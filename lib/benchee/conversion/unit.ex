defmodule Benchee.Conversion.Unit do
  defstruct [:name, :magnitude, :label, :long]

  alias Benchee.Conversion.Unit

  def scale(value, %Unit{magnitude: magnitude}) do
    value / magnitude
  end
end
