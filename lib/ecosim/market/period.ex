defmodule Ecosim.Market.Period do
  alias Ecosim.Market.Action

  defstruct actions: []

  @type t() :: %__MODULE__{
          actions: [Action.t()]
        }

  @spec create() :: t()
  def create() do
    %__MODULE__{actions: []}
  end

  def add_action(%__MODULE__{} = period, action, params) do
    action = Action.create(action, params)

    %__MODULE__{
      actions: List.insert_at(period.actions, -1, action)
    }
  end

  def last_action(%__MODULE__{} = period) do
    List.last(period.actions)
  end
end
