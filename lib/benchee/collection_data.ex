defmodule Benchee.CollectionData do
  @moduledoc """
  The unified data structure for a given collection of data.

  Consists of the recorded `samples` and the statistics computed from them.
  """

  alias Benchee.Statistics

  defstruct statistics: %Statistics{}, samples: []

  @typedoc """
  Samples and statistics.

  Statistics might only come later when they are computed.
  """
  @type t :: %__MODULE__{
          samples: [float | non_neg_integer],
          statistics: Statistics.t()
        }
end
