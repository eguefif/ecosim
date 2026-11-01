defmodule Ecosim.Market do
  defstruct buyers: [], sellers: [], periods: []

  alias Ecosim.Market.Period
  alias Ecosim.Market.Action

  @type t() :: %__MODULE__{
          buyers: [String.t()],
          sellers: [String.t()],
          periods: [Period.t()]
        }

  @spec new([String.t()], [String.t()]) :: t()
  def new(buyers, sellers) do
    period = Period.new()

    %__MODULE__{
      buyers: buyers,
      sellers: sellers,
      periods: [period]
    }
  end

  @doc """
  Update the market according to the action and params.
  """
  def update(market, action, params \\ %{})

  @spec update(t(), atom()) :: t()
  def update(%__MODULE__{} = market, :add_period, _) do
    %__MODULE__{
      market
      | periods: [Period.new() | market.periods]
    }
  end

  @spec update(t(), atom(), map()) :: t()
  def update(%__MODULE__{} = market, action, params) when action in [:buy_at, :sell_at] do
    %{
      market
      | periods:
          List.update_at(market.periods, -1, fn period ->
            Period.add_action(period, action, params)
          end)
    }
  end

  def update(%__MODULE__{} = market, :accept, params) do
    %{actor: actor, price: price} = params
    period = List.last(market.periods)

    market
    |> get_actor_list(actor)
    |> add_transaction(market, actor, price, period)
  end

  @spec get_actor_list(t(), String.t()) :: [String.t()]
  defp get_actor_list(market, actor) do
    case what_is_actor(market, actor) do
      :buyer -> market.sellers
      :seller -> market.buyers
      _ -> raise "Error: unknown actor type"
    end
  end

  @spec add_transaction([String.t()], t(), String.t(), float(), Period.t()) :: t()
  defp add_transaction(actor_list, market, actor, price, period) do
    case Period.get_last_offer_from(period, actor_list) do
      nil ->
        market

      %Action{params: %{actor: actor2}} ->
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
    end
  end

  @spec what_is_actor(t(), String.t()) :: :buyer | :seller | :unknown
  defp what_is_actor(market, actor) do
    is_buyer = actor in market.buyers
    is_seller = actor in market.sellers

    case actor do
      _ when is_buyer -> :buyer
      _ when is_seller -> :seller
      _ -> :unknown
    end
  end

  @doc """
  Retrieve the last action from the current period.
  """
  @spec last_action(t()) :: Action.t()
  def last_action(%__MODULE__{} = market) do
    List.last(market.periods) |> Period.last_action()
  end
end
