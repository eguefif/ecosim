defmodule Ecosim.Sim.Market do
  @moduledoc """
  This is the Market simulation. It uses the Vernon Smith protocol
  describeb in `An Experimental Study of Competitive Market Behavior - 1962`.

  Actors are divided in buyers and sellers. They both have a willingness to do something.
  Buyers have a WTB, Willingness To Buy. It's price above which they won't buy.
  Sellers have a WTA, Willingness To Accept to sell. It's a price underneath which they won't sell.

  A simulation is divided in period. which are composed of actions:
  - buy_at: a buyer offers to buy at a price.
  - sell_at: a seller offers to sell at a price.
  - accept the last price.

  An actor can do an action at any given time. When someone accept a price, both the seller and
  the buyer are removed from the period.

  A period ends when action `add_period` is used or when there is no more buyers and sellers.
  Any time a new period is created, buyers and sellers get back to the simulation with the same
  WTA and WTB.
  """
  defstruct buyers: [], sellers: [], periods: []

  alias Ecosim.Sim.Market.Period
  alias Ecosim.Sim.Market.Action
  alias Ecosim.Sim.Market.Actor

  @type t() :: %__MODULE__{
          buyers: [Actor.t()],
          sellers: [Actor.t()],
          periods: [Period.t()]
        }

  @type action() :: :add_period | :buy_at | :sell_at | :accept

  @type buyers() :: [Actor.t()]
  @type sellers() :: [Actor.t()]
  @type price() :: number()

  @doc """
  Create a new Market with one period from a list of buyers and sellers.
  """
  @spec new(buyers(), sellers()) :: t()
  def new(buyers, sellers) do
    period = Period.new(buyers ++ sellers)

    %__MODULE__{
      buyers: buyers,
      sellers: sellers,
      periods: [period]
    }
  end

  @doc """
  Create a new Market from the buyers and sellers from another market
  """
  @spec new(t()) :: t()
  def new(%__MODULE__{sellers: sellers, buyers: buyers} = _) do
    new(buyers, sellers)
  end

  @doc """
  Update the market according to the action and params.
  Possible actions `t:action/0`:
  - :add_period: create a new period with the list of actors: buyers ++ sellers
  - :buy_at
  - :sell_at
  - :accept

  ### Params
  It depends on the action.
  - :add_period => no params
  - :buy_at, :sell_at => %{actor: Actor.t(), price: number()}
  - :accept => %{actor: Actor.t()}

  ### Accept

  When an actor accept a price, it will automactillay takes the price depending on what type
  the actor is. If their are buyers, it will take the last seller's price offer and vice versa.
  Then, it creates a transaction action in the list of events and removes both actors from the period
  list of actors.

  If there are no price offers, it returns the market with no modification.

  ### Error
  - :price_not_in_wt: means that for a buyer, price is above WTB, for a seller
                      price is below WTA.
  """
  @spec update(t(), :add_period) :: {:ok, t()}
  @spec update(t(), :accept, Action.accept_params()) :: {:ok, t()} | {:error, :price_not_in_wt}
  @spec update(t(), :buy_at | :sell_at, Action.offer_params()) ::
          {:ok, t()} | {:error, :price_not_in_wt}
  def update(%__MODULE__{} = market, :add_period) do
    {:ok,
     %__MODULE__{
       market
       | periods: List.insert_at(market.periods, -1, Period.new(market.buyers ++ market.sellers))
     }}
  end

  def update(%__MODULE__{} = market, :accept, %{actor: actor}) do
    period = List.last(market.periods)

    market
    |> get_actor_list(actor)
    |> add_transaction(market, actor, period)
  end

  def update(%__MODULE__{} = market, :offer, %{actor: actor, price: price} = params) do
    action = get_specific_action(market, actor)

    if Actor.price_regarding_wt?(actor, price) do
      {:ok,
       %{
         market
         | periods:
             List.update_at(market.periods, -1, fn period ->
               Period.add_action(period, action, params)
             end)
       }}
    else
      {:error, :price_not_in_wt}
    end
  end

  @spec get_specific_action(t(), Actor.t()) :: :sell_at | :buy_at
  defp get_specific_action(%__MODULE__{} = market, actor) do
    if actor in market.buyers, do: :buy_at, else: :sell_at
  end

  @spec get_actor_list(t(), Actor.t()) :: [Actor.t()]
  defp get_actor_list(market, actor) do
    case actor.type do
      :buyer -> market.sellers
      :seller -> market.buyers
    end
  end

  @spec add_transaction([Actor.t()], t(), Actor.t(), Period.t()) :: {:ok, t()} | {:error, atom()}
  defp add_transaction(actor_list, market, actor, period) do
    case Period.get_last_offer_from(period, actor_list) do
      :none ->
        {:ok, market}

      %Action{params: %{actor: actor2, price: price}} ->
        if Actor.price_regarding_wt?(actor, price) do
          {:ok,
           %{
             market
             | periods:
                 List.update_at(market.periods, -1, fn period ->
                   Period.add_action(period, :accept, %{
                     actors: [actor, actor2],
                     price: price
                   })
                 end)
           }}
        else
          {:error, :price_not_in_wt}
        end
    end
  end

  @doc """
  Retrieve the current period actions.
  """
  @spec actions(t()) :: [Action.t()]
  def actions(%__MODULE__{} = market) do
    List.last(market.periods) |> Period.actions()
  end

  @doc """
  Retrieve the actor from the name
  """
  @spec actor(t(), String.t()) :: Actor.t() | nil
  def actor(%__MODULE__{} = market, actor_name) do
    (market.buyers ++ market.sellers)
    |> Enum.find(&(&1.name == actor_name))
  end
end
