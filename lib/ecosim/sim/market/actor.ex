defmodule Ecosim.Sim.Market.Actor do
  @moduledoc """
  An actor in the Market is of two type: buyer or seller and has a name.

  # wt (willingness to do something).
  The buyer has a wtb: willingness to buy a product at a maximum price.
  The seller has a wta: willingness to accept a price to sell a product.
  """

  alias Ecosim.Sim.Market

  defstruct [:type, :name, :wt]

  @type t() :: %__MODULE__{
          type: :buyer | :seller,
          name: String.t(),
          wt: number()
        }

  @type new_params :: [String.t()]

  @spec new(:buyer | :seller, String.t(), Market.price()) :: t()
  def new(type, name, wt) do
    %__MODULE__{
      type: type,
      name: name,
      wt: wt
    }
  end

  @spec new(new_params()) :: t()
  def new(params) do
    [type, name, wt] = params

    %__MODULE__{
      type: type |> type_string_to_atom(),
      name: name,
      wt: wt |> Float.parse() |> elem(0)
    }
  end

  @doc """
  Converts an actor type keyword (French or English, case-insensitive) to its atom.
  Returns `nil` for an unknown keyword.
  """
  @spec type_string_to_atom(String.t()) :: :buyer | :seller | nil
  def type_string_to_atom(type) do
    case type |> String.trim() |> String.downcase() do
      t when t in ["acheteur", "buyer"] -> :buyer
      t when t in ["vendeur", "seller"] -> :seller
      _ -> nil
    end
  end

  @doc """
  Return true if the price is consistent with actor's WT.
  """
  @spec price_regarding_wt?(t(), number()) :: boolean()
  def price_regarding_wt?(%__MODULE__{wt: wt} = actor, price) do
    if actor.type == :buyer do
      price <= wt
    else
      price >= wt
    end
  end
end
