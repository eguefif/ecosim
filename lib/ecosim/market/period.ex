defmodule Ecosim.Market.Period do
  alias Ecosim.Market.Action

  defstruct actions: []

  @type t() :: %__MODULE__{
          actions: [Action.t()]
        }

  @spec new() :: t()
  def new() do
    %__MODULE__{actions: []}
  end

  @doc """
  Add an action to the list of actions.

  An action can be:
  - :buy_at
  - :sell_at
  - :accept
  """
  def add_action(%__MODULE__{} = period, action, params) do
    action = Action.new(action, params)

    %__MODULE__{
      actions: List.insert_at(period.actions, -1, action)
    }
  end

  @doc """
  Returns the last registered actions.
  """
  @spec last_action(t()) :: Action.t() | nil
  def last_action(%__MODULE__{} = period) do
    List.last(period.actions)
  end

  @doc """
  Get the last offer made by an acton from the given list.
  """
  @spec get_last_offer_from(t(), list()) :: Action.t() | nil
  def get_last_offer_from(%__MODULE__{} = period, actors) do
    period.actions
    |> Enum.filter(&(Action.get_actor(&1) in actors))
    |> List.last()
  end
end
