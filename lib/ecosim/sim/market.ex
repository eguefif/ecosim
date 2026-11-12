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
  @type accept_params() :: %{seller: Actor.t(), buyer: Actor.t(), price: number()}
  @type transaction() :: [%{index: integer(), price: number()}]

  @doc """
  Create a new Market with one period from a list of buyers and sellers.
  Or it creates a Market with one period from a list of name and a market model.
  The market model with define what WTs distribution to use.
  """
  @spec new(buyers(), sellers()) :: t()
  def new(buyers, sellers) when is_list(buyers) and is_list(sellers) do
    period = Period.new(buyers ++ sellers)

    %__MODULE__{
      buyers: buyers,
      sellers: sellers,
      periods: [period]
    }
  end

  @spec new([String.t()], integer()) :: t()
  def new(actors, market_model) when is_integer(market_model) and is_list(actors) do
    {buyers, sellers} =
      actors
      |> spread_actors_between_sellers_and_buyers()
      |> build_wts(market_model)

    period = Period.new(buyers ++ sellers)

    %__MODULE__{
      buyers: buyers,
      sellers: sellers,
      periods: [period]
    }
  end

  @spec spread_actors_between_sellers_and_buyers([String.t()]) :: {[String.t()], [String.t()]}
  defp(spread_actors_between_sellers_and_buyers(actors)) do
    half = div(length(actors), 2)

    actors
    |> Enum.split(half)
  end

  @spec build_wts({[String.t()], [String.t()]}, integer()) :: {[Actor.t()], [Actor.t()]}
  defp build_wts({buyers, sellers}, _market_model) do
    price = 100
    step = 2
    {create_buyers(buyers, price, step), create_sellers(sellers, price, step)}
  end

  @spec create_buyers([String.t()], integer(), number()) :: [Actor.t()]
  defp create_buyers(buyers, price, step) do
    start = price + div(length(buyers), 2) * step

    buyers
    |> Enum.map_reduce(start, fn name, wt ->
      {Actor.new(:buyer, name, wt), wt - step}
    end)
    |> elem(0)
  end

  @spec create_sellers([String.t()], integer(), number()) :: [Actor.t()]
  defp create_sellers(sellers, price, step) do
    start = price - div(length(sellers), 2) * step

    sellers
    |> Enum.map_reduce(start, fn name, wt ->
      {Actor.new(:seller, name, wt), wt + step}
    end)
    |> elem(0)
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
  @spec update(t(), :accept, accept_params(), integer()) ::
          {:ok, t()} | {:error, :price_not_in_wt}
  @spec update(t(), :offer, Action.offer_params(), integer()) ::
          {:ok, t()} | {:error, :price_not_in_wt}
  def update(%__MODULE__{} = market, :add_period) do
    {:ok,
     %__MODULE__{
       market
       | periods: List.insert_at(market.periods, -1, Period.new(market.buyers ++ market.sellers))
     }}
  end

  def update(%__MODULE__{} = market, action, params) do
    update(market, action, params, -1)
  end

  def update(
        %__MODULE__{} = market,
        :accept,
        %{buyer: buyer, seller: seller, price: price},
        period_index
      ) do
    if check_wt(buyer, price) && check_wt(seller, price) do
      {:ok,
       %__MODULE__{
         market
         | periods:
             List.update_at(market.periods, period_index, fn period ->
               Period.add_action(period, :accept, %{actors: [seller, buyer], price: price})
             end)
       }}
    else
      {:error, :price_not_in_wt}
    end
  end

  def update(%__MODULE__{} = market, :offer, %{actor: actor, price: price} = params, period_index) do
    action = get_specific_action(market, actor)

    if Actor.price_regarding_wt?(actor, price) do
      {:ok,
       %{
         market
         | periods:
             List.update_at(market.periods, period_index, fn period ->
               Period.add_action(period, action, params)
             end)
       }}
    else
      {:error, :price_not_in_wt}
    end
  end

  @spec check_wt(Actor.t(), number()) :: boolean()
  defp check_wt(%Actor{type: :buyer, wt: wt}, price), do: price <= wt
  defp check_wt(%Actor{type: :seller, wt: wt}, price), do: price >= wt

  @spec get_specific_action(t(), Actor.t()) :: :sell_at | :buy_at
  defp get_specific_action(%__MODULE__{} = market, actor) do
    if actor in market.buyers, do: :buy_at, else: :sell_at
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

  @doc """
  Remove the last action.
  """
  @spec undo(t()) :: t()
  def undo(%__MODULE__{} = market, period_index \\ -1) do
    periods =
      List.update_at(market.periods, period_index, fn period ->
        period |> Period.remove_last_action()
      end)

    %{market | periods: periods}
  end

  @doc """
  Returns the list of active actors for the given period.
  An active is one that has not been yet involved in a transaction.
  """
  @spec active_actors(t(), integer()) :: [Actor.t()]
  def active_actors(%__MODULE__{} = market, period \\ -1) do
    period = Enum.at(market.periods, period)
    actors = market.sellers ++ market.buyers
    Enum.filter(actors, fn actor -> actor in period.actors end)
  end

  @doc """
  Returns the list of transaction per period with the price.
  """
  @spec results(t()) :: [transaction()]
  def results(%__MODULE__{} = market) do
    market.periods
    |> Enum.flat_map(&Period.transactions/1)
    |> Enum.with_index()
    |> Enum.map(fn {%Action{params: %{price: price}}, index} -> %{x: index, y: price} end)
  end

  @doc """
  Return data for the market plot.
  """
  @spec market_plot_data(t()) :: [list()]
  def market_plot_data(%__MODULE__{} = market) do
    sellers =
      Enum.map(market.sellers, & &1.wt)
      |> Enum.sort()
      |> Enum.with_index(fn wt, idx ->
        %{x: idx + 1, y: wt}
      end)

    {buyers, _} =
      Enum.map(market.buyers, & &1.wt)
      |> Enum.sort()
      |> Enum.map_reduce(length(market.buyers), fn wt, acc ->
        {%{x: acc, y: wt}, acc - 1}
      end)

    [buyers, sellers]
  end

  @spec result_plot_data(t()) :: list()
  def result_plot_data(%__MODULE__{} = market) do
    Enum.flat_map(market.periods, & &1.actions)
    |> Enum.filter(&(&1.action == :transact))
    |> Enum.with_index(fn %{params: %{price: price}} = _, idx ->
      %{x: idx, y: price}
    end)
  end

  @doc """
  Return the number of transaction for each period.
  """
  @spec transaction_per_period_plot_data(t()) :: list()
  def transaction_per_period_plot_data(%__MODULE__{} = market) do
    market.periods
    |> Enum.with_index(fn period, idx ->
      quantity =
        Enum.filter(period.actions, &(&1.action == :transact))
        |> length()

      %{x: idx + 1, y: quantity}
    end)
  end
end
