defmodule Ecosim.Sim.Market.Action do
  @moduledoc """
  An action is made in a Market's period. There are three types:
  - :sell_at `t:offer_params/0`
  - :buy_at `t:offer_params/0`
  - :accept `t:accept_params/0`

  """
  defstruct [:action, params: %{}]

  alias Ecosim.Sim.Market.Actor

  @type t() :: %__MODULE__{
          action: :buy_at | :sell_at | :accept,
          params: map()
        }

  @type offer_params() :: %{actor: Actor.t(), price: number()}
  @type accept_params() :: %{actors: [Actor.t()], price: number()}

  @doc """
  Create a new actions from an action name and params.
  """
  @spec new(:accept, accept_params()) :: t()
  @spec new(:sell_at | :buy_at, offer_params()) :: t()
  def new(:accept, params) do
    %__MODULE__{
      action: :transact,
      params: params
    }
  end

  def new(action, params) when action in [:sell_at, :buy_at] do
    %__MODULE__{
      action: action,
      params: params
    }
  end

  @doc """
  Returns the Action actors.
  """
  @spec get_actor(t()) :: Actor.t()
  def get_actor(%__MODULE__{} = action) do
    Map.get(action.params, :actor)
  end

  @doc """
  Return true if action is transaction between two actors.
  """
  @spec is_transaction(t()) :: boolean
  def is_transaction(%__MODULE__{} = action) do
    action.action == :transact
  end

  @doc """
  Return true if action is of :buy_at or sell_at
  """
  @spec is_offer(t()) :: boolean
  def is_offer(%__MODULE__{} = action) do
    action.action in [:buy_at, :sell_at]
  end

  @doc """
  Return the price for the action.
  """
  @spec price(t()) :: number()
  def price(%__MODULE__{params: %{price: price}}), do: price
end
