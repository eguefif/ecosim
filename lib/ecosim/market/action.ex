defmodule Ecosim.Market.Action do
  defstruct [:action, params: %{}]

  alias Ecosim.Market.Actor

  @type t() :: %__MODULE__{
          action: atom(),
          params: map()
        }

  @spec new(:accept, map()) :: t()
  def new(:accept, params) do
    %__MODULE__{
      action: :transact,
      params: params
    }
  end

  @spec new(atom(), map()) :: t()
  def new(action, params) do
    %__MODULE__{
      action: action,
      params: params
    }
  end

  @spec get_actor(t()) :: Actor.t()
  def get_actor(%__MODULE__{} = action) do
    Map.get(action.params, :actor)
  end
end
