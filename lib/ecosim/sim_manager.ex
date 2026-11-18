defmodule Ecosim.SimManager do
  @moduledoc """
  The state of one simulation: its id, type, participants and the
  type-specific simulation state (`sim_state`).

  Its functions are pure, except the monitor helpers (`new/3`,
  `monitor_liveview/2`, `demonitor_liveview/1`), which must be called from
  inside the `Ecosim.SimServer` process that owns the monitor.
  """

  defstruct participants: [], id: nil, type: nil, sim_state: %{}, monitor_ref: nil

  @type t() :: %__MODULE__{
          participants: [String.t()],
          id: integer() | nil,
          type: atom() | nil,
          sim_state: map(),
          monitor_ref: reference() | nil
        }

  @doc """
  Create a new Sim from the type and an id.
  The id can be used for the join_code.

  Monitors `liveview_pid` from the calling process and stores the monitor
  reference in `monitor_ref`.
  """
  @spec new(atom(), integer(), pid()) :: t()
  def new(type, id, liveview_pid) do
    monitor_ref = Process.monitor(liveview_pid)

    %__MODULE__{
      participants: [],
      id: id,
      type: type,
      monitor_ref: monitor_ref
    }
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
  Create the simulation with the list of participants.
  It defines `sim_state` which is the Struct defined by one of the following:
  - Ecosim.Market
  """
  @spec create_simulation(t(), any()) :: t()
  def create_simulation(%__MODULE__{participants: participants, type: sim_type} = sim, params) do
    sim_state = make_sim(sim_type, participants, params)

    %__MODULE__{
      sim
      | sim_state: sim_state
    }
  end

  @spec make_sim(atom(), [String.t()], any()) :: map()
  defp make_sim(:market, participants, params) do
    Ecosim.Sim.Market.new(participants, params)
  end

  @doc """
  Give the join code.
  """
  @spec join_code(t()) :: integer()
  def join_code(%__MODULE__{} = sim) do
    sim.id
  end

  @doc """
  Add a participants to the simulation.
  """
  @spec add_participants(t(), String.t()) :: t()
  def add_participants(%__MODULE__{} = sim, participant) do
    %__MODULE__{
      sim
      | participants: [participant | sim.participants]
    }
  end

  @doc """
  Call the simulation update function.
  """
  @spec update_sim(t(), atom(), map()) :: t() | {:error, atom()}
  def update_sim(%__MODULE__{} = sim, command, params \\ %{}) do
    case Ecosim.SimulationProtocol.update(sim.sim_state, command, params) do
      {:ok, sim_state} -> %{sim | sim_state: sim_state}
      {:error, msg} -> {:error, msg}
    end
  end

  @doc """
  Call the simulation info function.
  """
  @spec info_sim(t()) :: t()
  def info_sim(%__MODULE__{} = sim) do
    %__MODULE__{
      sim
      | sim_state: Ecosim.SimulationProtocol.info(sim.sim_state)
    }
  end
end
