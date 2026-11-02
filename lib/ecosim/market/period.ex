defmodule Ecosim.Market.Period do
  @moduledoc """
  A period gather several actions.
  """
  alias Ecosim.Market.Action
  alias Ecosim.Market.Actor

  defstruct [:actors, actions: []]

  @type t() :: %__MODULE__{
          actions: [Action.t()],
          actors: [Actor.t()]
        }

  @spec new([Actor.t()]) :: t()
  def new(actors) do
    %__MODULE__{actions: [], actors: actors}
  end

  @doc """
  Add an action to the list of actions.

  An action can be:
  - :buy_at
  - :sell_at
  - :accept
  """
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
  Get the last offer made by an acton from the given list.
  """
  @spec get_last_offer_from(t(), [Actor.t()]) :: Action.t() | :none
  def get_last_offer_from(%__MODULE__{} = period, actors) do
    offer =
      period.actions
      |> Enum.filter(&is_actor_in_list(&1, actors))
      |> List.last()

    if is_nil(offer), do: :none, else: offer
  end

  defp is_actor_in_list(actor_name, actor_list) do
    actor = Action.get_actor(actor_name)
    actor_list = Enum.map(actor_list, fn actor -> actor.name end)
    actor.name in actor_list
  end
end
