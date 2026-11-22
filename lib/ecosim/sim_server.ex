defmodule Ecosim.SimServer do
  @moduledoc """
  A GenServer that runs one simulation.

  Each server is registered in `Ecosim.SimulationsRegistry` under its simulation
  id, so callers address it by id (which is also the join code) rather than by pid.

  The server monitors the LiveView that owns it and stops when that LiveView goes
  down. To hand the simulation over to another LiveView (e.g. before a
  `push_navigate`), call `demonitor_liveview/1` from the current LiveView, then
  `monitor_liveview/1` from the new one. If no LiveView registers within 30 seconds
  of a demonitor, the server stops.
  """

  use GenServer

  alias Ecosim.SimManager

  require Logger

  @typedoc "Id of a running simulation, also used as its join code."
  @type sim_id() :: non_neg_integer()

  # Client *****************************************8

  @doc """
  Start a new simulation of type `sim_type` and return its id.

  The calling process (normally a LiveView) is monitored: when it stops, the
  simulation stops too.

  Returns `{:error, {:already_started, pid}}` if the generated id is already used
  by a running simulation.
  """
  @spec start() :: {:ok, sim_id()} | {:error, term()} | :ignore
  def start() do
    id = :ets.update_counter(:sim_registry, :next_id, {2, 1, 100_000, 0})

    case GenServer.start(__MODULE__, {id, self()}, name: via(id)) do
      {:ok, _pid} -> {:ok, id}
      error -> error
    end
  end

  defp via(id), do: {:via, Registry, {Ecosim.SimulationsRegistry, id}}

  @doc """
  Add the `participants`' names to simulation `id`.

  See `Ecosim.SimManager.add_participants/2`.
  """
  @spec add_participants_to_simulation(sim_id(), [String.t()]) :: :ok
  def add_participants_to_simulation(id, participants),
    do: GenServer.call(via(id), {:add_participants, participants})

  @doc """
  Return the join code of simulation `id`.
  """
  @spec join_code(sim_id()) :: integer()
  def join_code(id), do: GenServer.call(via(id), :join_code)

  @doc """
  Return the simulation `id`, with its `sim_state` replaced by the info computed
  by `Ecosim.SimulationProtocol.info/1`.
  """
  @spec info(sim_id()) :: SimManager.t()
  def info(id), do: GenServer.call(via(id), :info)

  @doc """
  Apply `command` with `params` to simulation `id`.

  Returns `{:error, reason}` when the simulation rejects the command; the
  simulation state is then left unchanged.
  """
  @spec update(sim_id(), atom()) :: {:ok, map()} | {:error, atom()}
  @spec update(sim_id(), atom(), map()) :: {:ok, map()} | {:error, atom()}
  def update(id, command), do: GenServer.call(via(id), {:update, command, %{}})
  def update(id, command, params), do: GenServer.call(via(id), {:update, command, params})

  @doc """
  Make simulation `id` monitor the calling process instead of the previous
  LiveView.

  Call it from a LiveView's `mount/3` only when `connected?(socket)` is true:
  the disconnected render runs in a short-lived process that would stop the
  simulation as soon as it exits.
  """
  @spec monitor_liveview(sim_id()) :: :ok
  def monitor_liveview(id) do
    pid = self()
    GenServer.call(via(id), {:monitor_liveview, pid})
  end

  @doc """
  Stop monitoring the current LiveView of simulation `id`.

  Call it right before navigating away, so the simulation survives the old
  LiveView stopping. If no LiveView calls `monitor_liveview/1` within 30 seconds,
  the simulation stops.
  """
  @spec demonitor_liveview(sim_id()) :: :ok
  def demonitor_liveview(id) do
    GenServer.call(via(id), :demonitor_liveview)
  end

  @doc """
  Set the type of simulation `id` (e.g. `:market`).

  `sim_type` can be an atom or a string. See `Ecosim.SimManager.set_sim/2`.
  """
  @spec set_sim_type(sim_id(), atom() | String.t()) :: :ok
  def set_sim_type(id, sim_type) do
    GenServer.call(via(id), {:set_sim_type, sim_type})
  end

  @doc """
  Set the mode of simulation `id`.

  `sim_mode` can be an atom or a string. See `Ecosim.SimManager.set_mode/2`.
  """
  @spec set_sim_mode(sim_id(), atom() | String.t()) :: :ok
  def set_sim_mode(id, sim_mode) do
    GenServer.call(via(id), {:set_sim_mode, sim_mode})
  end

  @doc """
  Return the type of simulation `id`, or `nil` if it has not been set yet.
  """
  @spec type(sim_id()) :: atom() | nil
  def type(id) do
    GenServer.call(via(id), :type)
  end

  @doc """
  Return the mode of simulation `id`, or `nil` if it has not been set yet.
  """
  @spec mode(sim_id()) :: atom() | nil
  def mode(id) do
    GenServer.call(via(id), :mode)
  end

  @doc """
  Return the path to the simulation depending on the sim type.
  """
  @spec route_path(sim_id()) :: String.t()
  def route_path(id) do
    GenServer.call(via(id), :route_path)
  end

  @doc """
  Return the simulation participants list.
  """
  @spec sim_participants(sim_id()) :: list()
  def sim_participants(id) do
    GenServer.call(via(id), :participants)
  end

  @doc """
  Inspect the current simulation.
  """
  @spec inspect_sim(sim_id()) :: :ok
  def inspect_sim(id) do
    GenServer.cast(via(id), :inspect)
  end

  @doc """
  Create the simulation.
  """
  @spec create_simulation(sim_id()) :: :ok
  def create_simulation(id) do
    GenServer.call(via(id), :create_sim)
  end

  # Server ***************************************************************

  @impl true
  def init({id, liveview_pid}) do
    {:ok, SimManager.new(id, liveview_pid)}
  end

  def handle_call({:set_sim_type, sim_type}, _from, state) do
    sim = SimManager.set_sim(state, sim_type)
    {:reply, :ok, sim}
  end

  def handle_call({:set_sim_mode, sim_mode}, _from, state) do
    sim = SimManager.set_mode(state, sim_mode)
    {:reply, :ok, sim}
  end

  @impl true
  def handle_call({:add_participants, participants}, _from, state) do
    {:reply, :ok, SimManager.add_participants(state, participants)}
  end

  def handle_call(:join_code, _from, state) do
    {:reply, SimManager.join_code(state), state}
  end

  def handle_call(:info, _from, state) do
    {:reply, SimManager.info(state), state}
  end

  def handle_call({:update, command, params}, _from, state) do
    case SimManager.update(state, command, params) do
      {:error, msg} -> {:reply, {:error, msg}, state}
      state -> {:reply, {:ok, SimManager.info(state)}, state}
    end
  end

  def handle_call({:monitor_liveview, pid}, _from, state) do
    {:reply, :ok, SimManager.monitor_liveview(state, pid)}
  end

  def handle_call(:demonitor_liveview, _from, state) do
    Process.send_after(self(), :check_orphan, 30_000)
    {:reply, :ok, SimManager.demonitor_liveview(state)}
  end

  def handle_call(:type, _from, state) do
    {:reply, SimManager.type(state), state}
  end

  def handle_call(:mode, _from, state) do
    {:reply, SimManager.mode(state), state}
  end

  def handle_call(:route_path, _from, state) do
    {:reply, SimManager.route_path(state), state}
  end

  def handle_call(:participants, _from, state) do
    {:reply, state.participants, state}
  end

  def handle_call(:create_sim, _from, state) do
    sim = SimManager.create_simulation(state)
    {:reply, :ok, sim}
  end

  # handle_cast ************************************************************
  @impl true
  def handle_cast(:inspect, state) do
    {:noreply, state}
  end

  # handle_info *************************************************************

  @impl true
  def handle_info({:DOWN, ref, :process, _, _}, %SimManager{monitor_ref: ref} = state) do
    {:stop, :monitored_liveview_stoped, state}
  end

  def handle_info(:check_orphan, %SimManager{monitor_ref: nil} = state) do
    {:stop, :no_liveview_monitored, state}
  end

  # A LiveView re-registered before the orphan timer fired: nothing to do.
  def handle_info(:check_orphan, state), do: {:noreply, state}

  # Catch-all: log and ignore unexpected messages (e.g. a stale :DOWN from a
  # previous monitor) instead of crashing the simulation.
  def handle_info(msg, state) do
    Logger.warning("SimServer #{state.id} got unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end
end
