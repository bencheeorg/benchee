defmodule Benchee.Conversion.Unit do
  defstruct [:name, :magnitude, :label, :long]
  @type t :: %Benchee.Conversion.Unit{name:      atom,
                                      magnitude: non_neg_integer,
                                      label:     String.t,
                                      long:      String.t}

end
