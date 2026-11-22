defmodule Ecosim.Sim.SimManager do
  @moduledoc """
  The state of one simulation: its id, type, participants and the
  type-specific simulation state (`sim_state`).

  Its functions are pure, except the monitor helpers (`new/2`,
  `monitor_simulation_liveview/2`, `demonitor_simulation_liveview/2`,
  `monitor_participant_liveview/3`, `demonitor_participant_liveview/2`), which
  must be called from inside the `Ecosim.Sim.SimServer` process that owns the
  monitor.
  """

  use EcosimWeb, :verified_routes

  defstruct participants: [],
            id: nil,
            type: nil,
            sim_state: %{},
            simulation_liveview: nil,
            participants_liveviews: nil,
            mode: nil,
            subscribers: []

  @type t() :: %__MODULE__{
          participants: [String.t()],
          id: integer() | nil,
          type: atom() | nil,
          sim_state: map(),
          mode: atom() | nil,
          simulation_liveview: %{ref: reference(), pid: pid()} | nil,
          participants_liveviews: [%{ref: reference(), pid: pid(), name: String.t()}] | nil,
          subscribers: [pid()]
        }

  @doc """
  Create a new, empty simulation state with `id`.
  The id is also used as the join code.

  Monitors `liveview_pid` from the calling process, stores the monitor
  reference in `simulation_liveview` and subscribes `liveview_pid`.
  """
  @spec new(integer(), pid()) :: t()
  def new(id, liveview_pid) do
    monitor_ref = Process.monitor(liveview_pid)

    %__MODULE__{
      id: id,
      simulation_liveview: %{ref: monitor_ref, pid: liveview_pid},
      participants_liveviews: [],
      mode: nil,
      type: nil,
      subscribers: [liveview_pid]
    }
  end

  @doc """
  Add a pid to the pub sub subscription list
  """
  @spec subscribe(t(), pid()) :: t()
  def subscribe(%__MODULE__{subscribers: subscribers} = sim, pid) do
    %__MODULE__{
      sim
      | subscribers: [pid | subscribers]
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
  delivered is flushed from the mailbox. `liveview_pid` is added to the
  subscribers.
  """
  @spec monitor_simulation_liveview(t(), pid()) :: t()
  def monitor_simulation_liveview(%__MODULE__{} = sim, liveview_pid) do
    if sim.simulation_liveview, do: Process.demonitor(sim.simulation_liveview.ref, [:flush])
    monitor_ref = Process.monitor(liveview_pid)

    new_values = [
      simulation_liveview: %{ref: monitor_ref, pid: liveview_pid},
      subscribers: [liveview_pid | sim.subscribers]
    ]

    struct!(sim, new_values)
  end

  @doc """
  Stop monitoring the current LiveView and set `simulation_liveview` to `nil`.

  Any `:DOWN` message the monitor already delivered is flushed from the mailbox,
  and `liveview_pid` is removed from the subscribers.
  """
  @spec demonitor_simulation_liveview(t(), pid()) :: t()
  def demonitor_simulation_liveview(%__MODULE__{} = sim, liveview_pid) do
    if sim.simulation_liveview, do: Process.demonitor(sim.simulation_liveview.ref, [:flush])

    new_values = [
      simulation_liveview: nil,
      subscribers: sim.subscribers |> Enum.reject(&(&1 == liveview_pid))
    ]

    struct!(sim, new_values)
  end

  @doc """
  Monitor `liveview_pid` as the LiveView of participant `name`.

  The monitor is appended to `participants_liveviews`. When it fires, the
  owning `Ecosim.Sim.SimServer` removes the participant with
  `remove_participant_from_ref/2`.
  """
  @spec monitor_participant_liveview(t(), String.t(), pid()) :: t()
  def monitor_participant_liveview(%__MODULE__{} = sim, name, liveview_pid) do
    monitor_ref = Process.monitor(liveview_pid)

    new_values = [
      participants_liveviews:
        sim.participants_liveviews ++ [%{ref: monitor_ref, pid: liveview_pid, name: name}]
    ]

    struct!(sim, new_values)
  end

  @doc """
  Stop monitoring the LiveView of participant `name` and remove it from
  `participants_liveviews`. The participant stays in `participants`.

  Raises a `MatchError` if no LiveView is monitored for `name`.
  """
  @spec demonitor_participant_liveview(t(), String.t()) :: t()
  def demonitor_participant_liveview(%__MODULE__{} = sim, name) do
    %{ref: monitor_ref} = sim.participants_liveviews |> Enum.find(&(&1.name == name))
    Process.demonitor(monitor_ref)

    IO.puts("IN demonitor")
    IO.inspect(sim)

    new_values = [
      participants_liveview: sim.participants_liveviews |> Enum.reject(&(&1.name == name))
    ]

    IO.inspect(new_values)
    IO.puts("OUT")

    struct!(sim, new_values)
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
    new_values = %{
      participants: sim.participants ++ participants
    }

    struct!(sim, new_values)
  end

  @doc """
  Add one participant's name to the simulation.

  Its LiveView is monitored separately, with `monitor_participant_liveview/3`.
  """
  @spec add_participant(t(), String.t()) :: t()
  def add_participant(%__MODULE__{} = sim, participant) when is_binary(participant) do
    new_values = %{
      participants: sim.participants ++ [participant]
    }

    struct!(sim, new_values)
  end

  @doc """
  Takes a ref and remove the participant from the participants list
  and the monitoring system. It does not try to demonitor.
  """
  @spec remove_participant_from_ref(t(), reference()) :: t()
  def remove_participant_from_ref(%__MODULE__{} = sim, ref) do
    %{name: participant} = Enum.find(sim.participants_liveviews, &(&1.ref == ref))

    %__MODULE__{
      sim
      | participants_liveviews: Enum.reject(sim.participants_liveviews, &(&1.ref == ref)),
        participants: Enum.reject(sim.participants, &(&1 == participant))
    }
  end

  @doc """
  Replace the simulation participants with `participants`.
  """
  @spec set_participants(t(), [String.t()]) :: t()
  def set_participants(%__MODULE__{} = sim, participants) when is_list(participants) do
    %__MODULE__{sim | participants: participants}
  end

  @doc """
  Call the simulation update function.
  """
  @spec update(t(), atom(), map()) :: t() | {:error, atom()}
  def update(%__MODULE__{} = sim, command, params \\ %{}) do
    case Ecosim.Sim.SimulationProtocol.update(sim.sim_state, command, params) do
      {:ok, sim_state} -> %{sim | sim_state: sim_state}
      {:error, msg} -> {:error, msg}
    end
  end

  @doc """
  Call the simulation info function.
  """
  @spec info(t()) :: map()
  def info(%__MODULE__{} = sim) do
    Ecosim.Sim.SimulationProtocol.info(sim.sim_state)
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

  When `participant_name` is given, it is added as a URL-encoded `name`
  query param, e.g. `"/sim/market/42?name=Jean+Paul"`.
  """
  @spec route_path(t()) :: String.t()
  @spec route_path(t(), String.t()) :: String.t()
  def route_path(%__MODULE__{type: :market, id: id}), do: ~p"/sim/market/#{id}"

  def route_path(%__MODULE__{type: :market, id: id}, participant_name) do
    ~p"/sim/join-market/#{id}?name=#{participant_name}"
  end
end
