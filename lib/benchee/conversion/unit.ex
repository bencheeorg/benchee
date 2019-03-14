defmodule Benchee.Conversion.Unit do
  @moduledoc """
  A representation of the different units used in `Benchee.Conversion.Format`
  and `Benchee.Conversion.Scale` as well as the modules implementing these
  behaviours.

  A unit is characterized by:

  * name - an atom representation of the unit for easy access (`:microseconds`,
  `thousand`)
  * magnitude - compared to he base unit (the smallest unit) what's the factor
  you had to multiply it by to get back to the base unit. E.g. the thousand
  unit has a magnitude of `1_000`.
  * label - a string that is used as a unit label (`"K"` for a thousand f.ex.)
  * long - a string giving the long version of the label (`"Thousand"`)
  """

  defstruct [:name, :magnitude, :label, :long]

  @type t :: %Benchee.Conversion.Unit{
          name: atom,
          magnitude: non_neg_integer,
          label: String.t(),
          long: String.t()
        }
end
