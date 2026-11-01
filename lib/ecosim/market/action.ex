defmodule Ecosim.Market.Action do
  defstruct [:action, params: %{}]

  @type t() :: %__MODULE__{
          action: atom(),
          params: map()
        }

  @spec create(atom(), map()) :: t()
  def create(action, params) do
    %__MODULE__{
      action: action,
      params: params
    }
  end
end
