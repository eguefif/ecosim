defmodule Ecosim.Sim.Market.Period do
  @moduledoc """
  A period gathers several actions. It's part of a Market simulation.
  Think of a period as a day.
  There is a list of actors. Each time a transaction is made by two actors, they
  are removed from the period's actor list.
  """
  alias Ecosim.Sim.Market
  alias Ecosim.Sim.Market.Action
  alias Ecosim.Sim.Market.Actor

  defstruct [:actors, actions: []]

  @type t() :: %__MODULE__{
          actions: [Action.t()],
          actors: [Actor.t()]
        }

  @type period_info() :: %{
          last_seller_price: Market.price() | :none,
          last_buyer_price: Market.price() | :none,
          transactions: [Action.t()],
          events: [Action.t()]
        }

  @spec new([Actor.t()]) :: t()
  def new(actors) do
    %__MODULE__{actions: [], actors: actors}
  end

  @doc """
  Return information regarding the period.
  """
  @spec info(t()) :: period_info()
  def info(%__MODULE__{} = period) do
    %{
      last_seller_price: last_seller_price(period),
      last_buyer_price: last_buyer_price(period),
      transactions: transactions(period),
      events: events(period)
    }
  end

  @spec events(t()) :: [Action.t()]
  defp events(%__MODULE__{} = period) do
    period.actions
  end

  @spec transactions(t()) :: [Action.t()]
  defp transactions(%__MODULE__{} = period) do
    period.actions |> Enum.filter(&Action.is_transaction/1)
  end

  @spec last_buyer_price(t()) :: Market.price() | :none
  defp last_buyer_price(%__MODULE__{} = period) do
    buyers = Enum.filter(period.actors, &(&1.type == :buyer))

    case get_last_offer_from(period, buyers) do
      :none -> :none
      action -> Map.get(action.params, :price)
    end
  end

  @spec last_seller_price(t()) :: Market.price() | :none
  defp last_seller_price(%__MODULE__{} = period) do
    sellers = Enum.filter(period.actors, &(&1.type == :seller))

    case get_last_offer_from(period, sellers) do
      :none -> :none
      action -> Map.get(action.params, :price)
    end
  end

  @doc """
  Add an action to the list of actions when actors are in the list.
  If actors are not in the list, it returns the period as it was.

  An action can be:
  - :buy_at `t:offer_params/0`
  - :sell_at `t:offer_params/0`
  - :accept `t:accept_params/0`

  Note that accept action generates a :transact actions between two actors.
  """
  @spec add_action(t(), :accept, Action.accept_params()) :: t()
  @spec add_action(t(), :buy_at | :sell_at, Action.offer_params()) :: t()
  def add_action(%__MODULE__{} = period, :accept, %{actors: [actor1, actor2]} = params) do
    if actor1 in period.actors && actor2 in period.actors do
      action = Action.new(:accept, params)
      actors_to_remove = action.params |> Map.get(:actors) |> Enum.map(& &1.name)

      %__MODULE__{
        actors: Enum.reject(period.actors, fn actor -> actor.name in actors_to_remove end),
        actions: List.insert_at(period.actions, -1, action)
      }
    else
      period
    end
  end

  def add_action(%__MODULE__{} = period, action, %{actor: actor} = params) do
    if actor in period.actors do
      action = Action.new(action, params)

      %__MODULE__{
        period
        | actions: List.insert_at(period.actions, -1, action)
      }
    else
      period
    end
  end

  @doc """
  Returns period's actions.
  """
  @spec actions(t()) :: [Action.t()]
  def actions(%__MODULE__{} = period) do
    period.actions
  end

  @doc """
  Return the most recent actions since last transaction when actor is active.
  """
  @spec get_last_offer_from(t(), [Actor.t()]) :: Action.t() | :none
  def get_last_offer_from(%__MODULE__{} = period, actors) do
    actor_list = period.actors |> Enum.filter(&(&1 in actors))

    period.actions
    |> Enum.reverse()
    |> Enum.take_while(&(&1.action != :transact))
    |> Enum.find(:none, &actor_in_list?(&1, actor_list))
  end

  @spec actor_in_list?(Action.t(), [Actor.t()]) :: boolean()
  defp actor_in_list?(action, actor_list) when action.action != :transact do
    actor = Action.get_actor(action)
    actor in actor_list
  end
end
