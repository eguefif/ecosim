defmodule Ecosim.Sim.SimulatorState do
  use GenServer

  # Client ----------------------
  def start_link(first_value) do
    GenServer.start_link(__MODULE__, first_value, name: __MODULE__)
  end

  def next_id() do
    GenServer.call(__MODULE__, :get_next_id)
  end

  # Server -----------------------

  def init(next_id) do
    {:ok, next_id}
  end

  def handle_call(:get_next_id, _from, state) do
    if state < 100_000 do
      {:reply, state, state + 1}
    else
      {:reply, state, 0}
    end
  end
end
