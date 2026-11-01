defmodule Ecosim.Market do
  defstruct buyers: [], sellers: [], periods: []

  alias Ecosim.Market.Period
  alias Ecosim.Market.Action

  @type t() :: %__MODULE__{
          buyers: [String.t()],
          sellers: [String.t()],
          periods: [Period.t()]
        }

  @spec create([String.t()], [String.t()]) :: t()
  def create(buyers, sellers) do
    period = Period.create()

    %__MODULE__{
      buyers: buyers,
      sellers: sellers,
      periods: [period]
    }
  end

  @spec update(t(), atom()) :: t()
  def update(%__MODULE__{} = market, :add_period) do
    %__MODULE__{
      market
      | periods: [Period.create() | market.periods]
    }
  end

  @doc """
  Update the market according to the action and parms
  """
  @spec update(t(), atom(), map()) :: t()
  def update(%__MODULE__{} = market, action, params \\ %{}) when action in [:buy_at, :sell_at] do
    %{
      market
      | periods:
          List.update_at(market.periods, -1, fn period ->
            Period.add_action(period, action, params)
          end)
    }
  end

  @doc """

  """
  @spec last_action(t()) :: Action.t()
  def last_action(%__MODULE__{} = market) do
    List.last(market.periods) |> IO.inspect() |> Period.last_action()
  end
end
