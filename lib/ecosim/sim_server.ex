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
  @spec start(atom()) :: {:ok, sim_id()} | {:error, term()} | :ignore
  def start(sim_type) do
    id = :ets.update_counter(:sim_registry, :next_id, {2, 1, 100_000, 0})

    case GenServer.start(__MODULE__, {sim_type, id, self()}, name: via(id)) do
      {:ok, _pid} -> {:ok, id}
      error -> error
    end
  end

  defp via(id), do: {:via, Registry, {Ecosim.SimulationsRegistry, id}}

  @doc """
  Build the simulation state of simulation `id` from `participants`.

  See `Ecosim.SimManager.create_simulation/2`.
  """
  @spec add_participants_to_simulation(sim_id(), any()) :: :ok
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
  @spec update_sim(sim_id(), atom(), map()) :: :ok | {:error, atom()}
  def update_sim(id, command, params), do: GenServer.call(via(id), {:update, command, params})

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

  # Server *****************************************8

  @impl true
  def init({sim_type, id, liveview_pid}) do
    {:ok, SimManager.new(sim_type, id, liveview_pid)}
  end

  @impl true
  def handle_call({:add_participants, participants}, _from, state) do
    {:reply, :ok, SimManager.create_simulation(state, participants)}
  end

  def handle_call(:join_code, _from, state) do
    {:reply, SimManager.join_code(state), state}
  end

  def handle_call(:info, _from, state) do
    {:reply, SimManager.info_sim(state), state}
  end

  def handle_call({:update, command, params}, _from, state) do
    case SimManager.update_sim(state, command, params) do
      {:error, msg} -> {:reply, {:error, msg}, state}
      state -> {:reply, :ok, state}
    end
  end

  def handle_call({:monitor_liveview, pid}, _from, state) do
    {:reply, :ok, SimManager.monitor_liveview(state, pid)}
  end

  def handle_call(:demonitor_liveview, _from, state) do
    Process.send_after(self(), :check_orphan, 30_000)
    {:reply, :ok, SimManager.demonitor_liveview(state)}
  end

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
