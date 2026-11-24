defmodule Ecosim.Sim.DevSim do
  @moduledoc """
  Dev-only helper that keeps a market simulation with id `#{1}` always running,
  so participant LiveViews can be iterated on without recreating a simulation
  after every code reload.

  This process is the simulation's owner instead of a LiveView, so live reload
  never stops it. If the simulation crashes, it is started again.

  Enabled with `config :ecosim, start_dev_sim: true` (see `config/dev.exs`).
  Join it at `/sim/join-market/1?name=Alice` (or Bob, Carol, Dave).
  """

  use GenServer

  alias Ecosim.Sim.SimServer

  require Logger

  @sim_id 1
  # The first half become buyers, the second half sellers (see Market.new/2):
  # buyers' WTs: Alice 106, Bob 104, Carol 102, Dave 100, Eve 98, Frank 96
  # sellers' WTs: Grace 94, Heidi 96, Ivan 98, Judy 100, Mallory 102, Niaj 104
  @participants ~w(Alice Bob Carol Dave Eve Frank Grace Heidi Ivan Judy Mallory Niaj)

  # {buyer, seller, price}. Both actors leave the market after the transaction.
  @transactions [{"Eve", "Grace", 96}, {"Frank", "Heidi", 96}]

  # {actor, price}. Made after the transactions, since only offers made after
  # the last transaction are shown. Alice and Niaj are left free to play.
  @offers [
    {"Dave", 92},
    {"Bob", 95},
    {"Carol", 97},
    {"Mallory", 110},
    {"Judy", 108},
    {"Ivan", 105}
  ]

  def start_link(_opts), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @doc "Id (and join code) of the dev simulation."
  def sim_id, do: @sim_id

  @impl true
  def init(nil) do
    # Make sure real simulations created from the UI never get the dev id.
    [{:next_id, next_id}] = :ets.lookup(:sim_registry, :next_id)
    :ets.insert(:sim_registry, {:next_id, max(next_id, @sim_id)})
    {:ok, nil, {:continue, :start_sim}}
  end

  @impl true
  def handle_continue(:start_sim, _state) do
    {:ok, pid} =
      GenServer.start(SimServer, {@sim_id, self()},
        name: {:via, Registry, {Ecosim.SimulationsRegistry, @sim_id}}
      )

    ref = Process.monitor(pid)

    :ok = SimServer.set_sim_type(@sim_id, :market)
    :ok = SimServer.set_sim_mode(@sim_id, :multi)
    :ok = SimServer.set_participants(@sim_id, @participants)
    :ok = SimServer.create_simulation(@sim_id)
    # Go straight to the running market (:preparation -> :sim).
    {:ok, _info} = SimServer.update(@sim_id, :step_forward)

    # for {buyer, seller, price} <- @transactions do
    #  {:ok, _info} =
    #    SimServer.update(@sim_id, :accept, %{
    #      buyer: actor(buyer),
    #      seller: actor(seller),
    #      price: price
    #    })
    # end

    # for {name, price} <- @offers do
    #  {:ok, _info} = SimServer.update(@sim_id, :offer, %{actor: actor(name), price: price})
    # end

    Logger.info("DevSim: market simulation #{@sim_id} running with #{inspect(@participants)}")
    {:noreply, ref}
  end

  defp actor(name) do
    SimServer.info(@sim_id).active_actors |> Enum.find(&(&1.name == name))
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, reason}, ref) do
    Logger.warning("DevSim: simulation #{@sim_id} stopped (#{inspect(reason)}), restarting")
    {:noreply, nil, {:continue, :start_sim}}
  end

  # SimServer broadcasts to its owner (:update, :new_participants, ...): ignore.
  def handle_info(_msg, state), do: {:noreply, state}
end
