defmodule Ecosim.Market do
  defstruct buyers: [], sellers: [], periods: []

  alias Ecosim.Market.Period
  alias Ecosim.Market.Action
  alias Ecosim.Market.Actor

  @type t() :: %__MODULE__{
          buyers: [String.t()],
          sellers: [String.t()],
          periods: [Period.t()]
        }

  @spec new([String.t()], [String.t()]) :: t()
  def new(buyers, sellers) do
    period = Period.new(buyers ++ sellers)

    %__MODULE__{
      buyers: buyers,
      sellers: sellers,
      periods: [period]
    }
  end

  @doc """
  Update the market according to the action and params.
  Possible actions:
  - :add_period
  - :buy_at
  - :sell_at
  - :accept
  """
  def update(market, action, params \\ %{})

  @spec update(t(), atom()) :: t() | {:error, atom()}
  def update(%__MODULE__{} = market, :add_period, _) do
    %__MODULE__{
      market
      | periods: [Period.new(market.buyers ++ market.sellers) | market.periods]
    }
  end

  @spec update(t(), atom(), map()) :: t()
  def update(%__MODULE__{} = market, action, params) when action in [:buy_at, :sell_at] do
    %{actor: actor, price: price} = params

    if Actor.price_regarding_wt?(actor, price) do
      %{
        market
        | periods:
            List.update_at(market.periods, -1, fn period ->
              Period.add_action(period, action, params)
            end)
      }
    else
      {:error, :price_not_in_wt}
    end
  end

  def update(%__MODULE__{} = market, :accept, params) do
    %{actor: actor} = params
    period = List.last(market.periods)

    market
    |> get_actor_list(actor)
    |> add_transaction(market, actor, period)
  end

  @spec get_actor_list(t(), Actor.t()) :: [String.t()]
  defp get_actor_list(market, actor) do
    case actor.type do
      :buyer -> market.sellers
      :seller -> market.buyers
    end
  end

  @spec add_transaction([Actor.t()], t(), Actor.t(), Period.t()) :: t()
  defp add_transaction(actor_list, market, actor, period) do
    case Period.get_last_offer_from(period, actor_list) do
      nil ->
        market

      %Action{params: %{actor: actor2, price: price}} ->
        if Actor.price_regarding_wt?(actor, price) do
          %{
            market
            | periods:
                List.update_at(market.periods, -1, fn period ->
                  Period.add_action(period, :accept, %{
                    actors: [actor, actor2],
                    price: price
                  })
                end)
          }
        else
          {:error, :price_not_in_wt}
        end
    end
  end

  @doc """
  Retrieve the current period actions.
  """
  @spec actions(t()) :: Action.t()
  def actions(%__MODULE__{} = market) do
    List.last(market.periods) |> Period.actions()
  end
end
