defmodule Benchee.CollectionData do
  @moduledoc """
  The unified data structure for a given collection of data.
  """

  defstruct statistics: %Benchee.Statistics{}, samples: []

  @type t :: %__MODULE__{
          samples: [float | non_neg_integer],
          statistics: Benchee.Statistics.t() | nil
        }
end
