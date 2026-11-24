defmodule Ecosim.Sim.SimServer do
  @moduledoc """
  A GenServer that runs one simulation.

  Each server is registered in `Ecosim.SimulationsRegistry` under its simulation
  id, so callers address it by id (which is also the join code) rather than by pid.

  The server monitors the LiveView that owns it and stops when that LiveView goes
  down. To hand the simulation over to another LiveView (e.g. before a
  `push_navigate`), call `demonitor_simulation_liveview/1` from the current LiveView, then
  `monitor_simulation_liveview/1` from the new one. If no LiveView registers within 30 seconds
  of a demonitor, the server stops.
  """

  use GenServer

  alias Ecosim.Sim.SimManager

  require Logger

  @typedoc "Id of a running simulation, also used as its join code."
  @type sim_id() :: non_neg_integer()

  # Client *****************************************8

  @doc """
  Start a new, empty simulation and return its id.

  The type, mode and participants are set afterwards with `set_sim_type/2`,
  `set_sim_mode/2` and `set_participants/2`.

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

  @doc """
  Returns true if the simulation id matches an existing simulation.
  """
  @spec simulation?(sim_id()) :: boolean()
  def simulation?(id) do
    case Registry.lookup(Ecosim.SimulationsRegistry, id) do
      [_] -> true
      [] -> false
    end
  end

  defp via(id), do: {:via, Registry, {Ecosim.SimulationsRegistry, id}}

  @doc """
  Add the `participants`' names to simulation `id`.

  See `Ecosim.Sim.SimManager.add_participants/2`.
  """
  @spec add_participants_to_simulation(sim_id(), [String.t()]) :: :ok
  def add_participants_to_simulation(id, participants) do
    GenServer.call(via(id), {:add_participants, participants})
  end

  @doc """
  Add the participant `name` to simulation `id`.

  The participant's LiveView is not monitored here; call
  `monitor_participant_liveview/2` from that LiveView for that.

  See `Ecosim.Sim.SimManager.add_participant/2`.
  """
  @spec add_participant_to_simulation(sim_id(), String.t()) :: :ok
  def add_participant_to_simulation(id, name) do
    GenServer.call(via(id), {:add_participant, name})
  end

  @doc """
  Replace the participants of simulation `id` with `participants`.

  Calling it several times with the same list is safe, unlike
  `add_participants_to_simulation/2`.

  See `Ecosim.Sim.SimManager.set_participants/2`.
  """
  @spec set_participants(sim_id(), [String.t()]) :: :ok
  def set_participants(id, participants) do
    GenServer.call(via(id), {:set_participants, participants})
  end

  @doc """
  Return the join code of simulation `id`.
  """
  @spec join_code(sim_id()) :: integer()
  def join_code(id), do: GenServer.call(via(id), :join_code)

  @doc """
  Return the info of simulation `id`, as computed by
  `Ecosim.SimulationProtocol.info/1`. Its content depends on the simulation
  type and step.
  """
  @spec info(sim_id()) :: map()
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
  @spec monitor_simulation_liveview(sim_id()) :: :ok
  def monitor_simulation_liveview(id) do
    pid = self()
    GenServer.call(via(id), {:monitor_simulation_liveview, pid})
  end

  @doc """
  Stop monitoring the current LiveView of simulation `id`.

  Call it right before navigating away, so the simulation survives the old
  LiveView stopping. If no LiveView calls `monitor_simulation_liveview/1` within 30 seconds,
  the simulation stops.
  """
  @spec demonitor_simulation_liveview(sim_id()) :: :ok
  def demonitor_simulation_liveview(id) do
    GenServer.call(via(id), {:demonitor_simulation_liveview, self()})
  end

  @doc """
  Make simulation `id` monitor the calling process as the LiveView of
  participant `name`.

  When that LiveView stops, the participant is removed from the simulation.
  As with `monitor_simulation_liveview/1`, call it from `mount/3` only when
  `connected?(socket)` is true.

  See `Ecosim.Sim.SimManager.monitor_participant_liveview/3`.
  """
  @spec monitor_participant_liveview(sim_id(), String.t()) :: :ok
  def monitor_participant_liveview(id, name) do
    GenServer.call(via(id), {:monitor_participant_liveview, name, self()})
  end

  @doc """
  Stop monitoring the LiveView of participant `name` in simulation `id`.

  Call it right before the participant's LiveView navigates away, so the
  participant is not removed when the old LiveView stops.

  See `Ecosim.Sim.SimManager.demonitor_participant_liveview/2`.
  """
  @spec demonitor_participant_liveview(sim_id(), String.t()) :: :ok
  def demonitor_participant_liveview(id, name) do
    GenServer.call(via(id), {:demonitor_participant_liveview, name})
  end

  @doc """
  Set the type of simulation `id` (e.g. `:market`).

  `sim_type` can be an atom or a string. See `Ecosim.Sim.SimManager.set_sim/2`.
  """
  @spec set_sim_type(sim_id(), atom() | String.t()) :: :ok
  def set_sim_type(id, sim_type) do
    GenServer.call(via(id), {:set_sim_type, sim_type})
  end

  @doc """
  Set the mode of simulation `id`.

  `sim_mode` can be an atom or a string. See `Ecosim.Sim.SimManager.set_mode/2`.
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
  Return the path of the LiveView that runs simulation `id`, depending on its
  type.

  With `participant_name`, return the path a participant uses to join the
  simulation instead.

  See `Ecosim.Sim.SimManager.route_path/1` and
  `Ecosim.Sim.SimManager.route_path/2`.
  """
  @spec route_path(sim_id()) :: String.t()
  @spec route_path(sim_id(), String.t()) :: String.t()
  def route_path(id) do
    GenServer.call(via(id), :route_path)
  end

  def route_path(id, participant_name) do
    GenServer.call(via(id), {:route_path, participant_name})
  end

  @doc """
  Return the simulation participants list.
  """
  @spec sim_participants(sim_id()) :: [String.t()]
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

  @doc """
  Suscribe the caller process to the pub sub list.
  """
  @spec subscribe(sim_id()) :: :ok
  def subscribe(id) do
    pid = self()
    GenServer.cast(via(id), {:subscribe, pid})
  end

  # Server ***************************************************************

  @impl true
  def init({id, liveview_pid}) do
    {:ok, SimManager.new(id, liveview_pid)}
  end

  @impl true
  def handle_call({:set_sim_type, sim_type}, _from, state) do
    sim = SimManager.set_sim(state, sim_type)
    {:reply, :ok, sim}
  end

  def handle_call({:set_sim_mode, sim_mode}, _from, state) do
    sim = SimManager.set_mode(state, sim_mode)
    {:reply, :ok, sim}
  end

  def handle_call({:add_participants, participants}, _from, state) do
    broadcast(:new_participants, state)
    {:reply, :ok, SimManager.add_participants(state, participants)}
  end

  def handle_call({:add_participant, participant}, _from, state) do
    broadcast(:new_participants, state)
    {:reply, :ok, SimManager.add_participant(state, participant)}
  end

  def handle_call({:set_participants, participants}, _from, state) do
    state = SimManager.set_participants(state, participants)
    broadcast(:new_participants, state)
    {:reply, :ok, state}
  end

  def handle_call(:join_code, _from, state) do
    {:reply, SimManager.join_code(state), state}
  end

  def handle_call(:info, _from, state) do
    {:reply, SimManager.info(state), state}
  end

  def handle_call({:update, command, params}, _from, state) do
    case SimManager.update(state, command, params) do
      {:error, msg} ->
        {:reply, {:error, msg}, state}

      state ->
        broadcast(:update, state)
        {:reply, {:ok, SimManager.info(state)}, state}
    end
  end

  def handle_call({:monitor_simulation_liveview, pid}, _from, state) do
    {:reply, :ok, SimManager.monitor_simulation_liveview(state, pid)}
  end

  def handle_call({:demonitor_simulation_liveview, liveview_pid}, _from, state) do
    Process.send_after(self(), :check_orphan, 30_000)
    {:reply, :ok, SimManager.demonitor_simulation_liveview(state, liveview_pid)}
  end

  def handle_call({:monitor_participant_liveview, name, pid}, _from, state) do
    {:reply, :ok, SimManager.monitor_participant_liveview(state, name, pid)}
  end

  def handle_call({:demonitor_participant_liveview, name}, _from, state) do
    Process.send_after(self(), :check_orphan, 30_000)
    {:reply, :ok, SimManager.demonitor_participant_liveview(state, name)}
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

  def handle_call({:route_path, participant_name}, _from, state) do
    {:reply, SimManager.route_path(state, participant_name), state}
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

  def handle_cast({:subscribe, pid}, state) do
    {:noreply, state |> SimManager.subscribe(pid)}
  end

  # handle_info *************************************************************

  @impl true
  def handle_info(
        {:DOWN, ref, :process, _, _},
        %SimManager{simulation_liveview: %{ref: ref}} = state
      ) do
    broadcast_participants(:simulation_finished, state)
    {:stop, :monitored_liveview_stoped, state}
  end

  # We want to unlist the participants who's liveview's has stoped.
  def handle_info(
        {:DOWN, ref, :process, _, _},
        %SimManager{participants_liveviews: liveviews} = state
      ) do
    state =
      if Enum.any?(liveviews, &(&1.ref == ref)) do
        broadcast(:remove_participant, state)
        SimManager.remove_participant_from_ref(state, ref)
      end

    {:noreply, state}
  end

  def handle_info(:check_orphan, %SimManager{simulation_liveview: nil} = state) do
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

  # pubsub function ****************************

  @doc """
  Send `message` to every subscriber of the simulation `state`, including the
  simulation LiveView.
  """
  @spec broadcast(term(), SimManager.t()) :: :ok
  def broadcast(message, state) do
    state.subscribers |> Enum.each(&send(&1, message))
  end

  @doc """
  Send `message` to every subscriber of the simulation `state` except the
  simulation LiveView, i.e. to the participants only.

  Expects `state.simulation_liveview` to be set.
  """
  @spec broadcast_participants(term(), SimManager.t()) :: :ok
  def broadcast_participants(message, state) do
    %{pid: liveview_pid} = state.simulation_liveview

    state.subscribers
    |> Enum.reject(&(&1 == liveview_pid))
    |> Enum.each(&send(&1, message))
  end
end
