defmodule Ecosim.SimManager do
  @moduledoc """
  The state of one simulation: its id, type, participants and the
  type-specific simulation state (`sim_state`).

  Its functions are pure, except the monitor helpers (`new/3`,
  `monitor_liveview/2`, `demonitor_liveview/1`), which must be called from
  inside the `Ecosim.SimServer` process that owns the monitor.
  """

  use EcosimWeb, :verified_routes

  defstruct participants: [], id: nil, type: nil, sim_state: %{}, monitor_ref: nil, mode: nil

  @type t() :: %__MODULE__{
          participants: [String.t()],
          id: integer() | nil,
          type: atom() | nil,
          sim_state: map(),
          mode: atom() | nil,
          monitor_ref: reference() | nil
        }

  @doc """
  Create a new Sim from the type and an id.
  The id can be used for the join_code.

  Monitors `liveview_pid` from the calling process and stores the monitor
  reference in `monitor_ref`.
  """
  @spec new(integer(), pid()) :: t()
  def new(id, liveview_pid) do
    monitor_ref = Process.monitor(liveview_pid)

    %__MODULE__{
      id: id,
      monitor_ref: monitor_ref,
      mode: nil,
      type: nil
    }
  end

  @doc """
  Set the simulation type (e.g. `:market`).

  `sim_type` can be an atom or a string; a string is converted to an atom.
  """
  @spec set_sim(t(), atom() | String.t()) :: t()
  def set_sim(%__MODULE__{} = sim, sim_type) when is_atom(sim_type) do
    %__MODULE__{
      sim
      | type: sim_type
    }
  end

  def set_sim(%__MODULE__{} = sim, sim_type) when is_binary(sim_type) do
    sim_type = String.to_atom(sim_type)

    %__MODULE__{
      sim
      | type: sim_type
    }
  end

  @doc """
  Set the simulation mode.

  `mode` can be an atom or a string; a string is converted to an atom.
  """
  @spec set_mode(t(), atom() | String.t()) :: t()
  def set_mode(%__MODULE__{} = sim, mode) when is_atom(mode) do
    %__MODULE__{
      sim
      | mode: mode
    }
  end

  def set_mode(%__MODULE__{} = sim, mode) when is_binary(mode) do
    mode =
      if mode == "one-for-all" do
        :one_for_all
      else
        String.to_atom(mode)
      end

    %__MODULE__{
      sim
      | mode: mode
    }
  end

  @doc """
  Return the simulation type, or `nil` if it has not been set yet.
  """
  @spec type(t()) :: atom() | nil
  def type(%__MODULE__{} = sim) do
    sim.type
  end

  @doc """
  Return the simulation mode, or `nil` if it has not been set yet.
  """
  @spec mode(t()) :: atom() | nil
  def mode(%__MODULE__{} = sim) do
    sim.mode
  end

  @doc """
  Monitor `liveview_pid` instead of the currently monitored LiveView.

  The previous monitor, if any, is removed, and any `:DOWN` message it already
  delivered is flushed from the mailbox.
  """
  @spec monitor_liveview(t(), pid()) :: t()
  def monitor_liveview(%__MODULE__{} = sim, liveview_pid) do
    if sim.monitor_ref, do: Process.demonitor(sim.monitor_ref, [:flush])
    monitor_ref = Process.monitor(liveview_pid)

    %__MODULE__{
      sim
      | monitor_ref: monitor_ref
    }
  end

  @doc """
  Stop monitoring the current LiveView and set `monitor_ref` to `nil`.

  Any `:DOWN` message the monitor already delivered is flushed from the mailbox.
  """
  @spec demonitor_liveview(t()) :: t()
  def demonitor_liveview(%__MODULE__{} = sim) do
    if sim.monitor_ref, do: Process.demonitor(sim.monitor_ref, [:flush])

    %__MODULE__{
      sim
      | monitor_ref: nil
    }
  end

  @doc """
  Give the join code.
  """
  @spec join_code(t()) :: integer()
  def join_code(%__MODULE__{} = sim) do
    sim.id
  end

  @doc """
  Add a list of participants' names to the simulation.
  """
  @spec add_participants(t(), [String.t()]) :: t()
  def add_participants(%__MODULE__{} = sim, participants) when is_list(participants) do
    %__MODULE__{
      sim
      | participants: sim.participants ++ participants
    }
  end

  @doc """
  Call the simulation update function.
  """
  @spec update(t(), atom(), map()) :: t() | {:error, atom()}
  def update(%__MODULE__{} = sim, command, params \\ %{}) do
    case Ecosim.SimulationProtocol.update(sim.sim_state, command, params) do
      {:ok, sim_state} -> %{sim | sim_state: sim_state}
      {:error, msg} -> {:error, msg}
    end
  end

  @doc """
  Call the simulation info function.
  """
  @spec info(t()) :: map()
  def info(%__MODULE__{} = sim) do
    Ecosim.SimulationProtocol.info(sim.sim_state)
  end

  @doc """
  Create simulation from the information provided in the SimulationManager Struct
  """
  @spec create_simulation(t()) :: t()
  def create_simulation(%__MODULE__{participants: participants, type: :market} = sim) do
    %__MODULE__{
      sim
      | sim_state: Ecosim.Sim.Market.new(participants, 1)
    }
  end

  @doc """
  Return the path of the LiveView that runs the simulation, e.g.
  `"/sim/market/42"` for a market simulation with id `42`.
  """
  @spec route_path(t()) :: String.t()
  def route_path(%__MODULE__{type: :market, id: id}), do: ~p"/sim/market/#{id}"
end
