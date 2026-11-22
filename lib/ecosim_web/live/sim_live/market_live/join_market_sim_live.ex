defmodule EcosimWeb.SimLive.MarketLive.JoinMarketSimLive do
  use EcosimWeb, :live_view

  alias Ecosim.Sim.SimServer

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {title(@simulation_status)} - {@name}
      </.header>
      <.waiting_screen :if={@simulation_status == :waiting} />
      <.sim_screen :if={@simulation_status == :running} />
      <.end_screen :if={@simulation_status == :finished} />
    </Layouts.app>
    """
  end

  def waiting_screen(assigns) do
    ~H"""
    <div class="flex flex-col justify-center items-center w-full">
      <div class="aura">
        <div class="card bg-base-200 text-md shadow-md">
          <div class="card-body">
            {gettext("Waiting for the simulation to start...")}
          </div>
        </div>
      </div>
    </div>
    """
  end

  def sim_screen(assigns) do
    ~H"""
    <div class="flex flex-col justify-center items-center w-full">
      "Running"
    </div>
    """
  end

  def end_screen(assigns) do
    ~H"""
    <div class="flex flex-col justify-center items-center w-full">
      {gettext("The simulation is finished")}
    </div>
    """
  end

  def title(:waiting), do: gettext("Welcome to this simulation")
  def title(:running), do: gettext("Market is opened")
  def title(:results), do: gettext("Results")

  @impl true
  def mount(%{"sim_id" => sim_id, "name" => name} = _, _session, socket) do
    sim_id = String.to_integer(sim_id)
    SimServer.subscribe(sim_id)
    SimServer.monitor_participant_liveview(sim_id, name)

    status =
      case SimServer.simulation?(sim_id) do
        true -> :waiting
        false -> :finished
      end

    {:ok,
     socket
     |> assign(:name, name)
     |> assign(:info, nil)
     |> assign(:sim_id, sim_id)
     |> assign(:simulation_status, status)}
  end

  @impl true
  def handle_info(:simulation_finished, socket) do
    {:noreply, socket |> assign(:simulation_status, :finished)}
  end

  @impl true
  def handle_info(:start, socket) do
    SimServer.demonitor_participant_liveview(socket.assigns.sim_id, socket.assigns.name)
    {:noreply, socket |> assign(:simulation_status, :finished)}
  end

  def handle_info(:update, socket) do
    info = SimServer.info(socket.assigns.sim_id)

    socket = assign(socket, :info, info)

    case info.step do
      :preparation -> {:noreply, socket |> assign(:simulation_status, :waiting)}
      :sim -> {:noreply, socket |> assign(:simulation_status, :running)}
      :result -> {:noreply, socket |> assign(:simulation_status, :finished)}
    end
  end

  def handle_info(:new_participants, socket) do
    {:noreply, socket}
  end

  def handle_info(:remove_participant, socket) do
    {:noreply, socket}
  end
end
