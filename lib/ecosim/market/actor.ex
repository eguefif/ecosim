defmodule Ecosim.Market.Actor do
  @moduledoc """
  An actor in the Market is of two type: buyer or seller and has a name.

  # wt (willingness to do something).
  The buyer has a wtb: willingness to buy a product at a maximum price.
  The seller has a wta: willingness to accept a price to sell a product.
  """

  defstruct [:type, :name, :wt]

  @type t() :: %__MODULE__{
          type: :buyer | :seller,
          name: String.t(),
          wt: float()
        }

  @spec new(:buyer | :seller, String.t(), float()) :: t()
  def new(type, name, wt) do
    %__MODULE__{
      type: type,
      name: name,
      wt: wt
    }
  end
end
