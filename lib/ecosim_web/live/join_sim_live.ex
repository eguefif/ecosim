defmodule EcosimWeb.JoinSimLive do
  use EcosimWeb, :live_view

  alias Ecosim.Sim.SimServer

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <.header>
          {gettext("Join a simulation")}
        </.header>

        <form id="join-sim-form" phx-submit="join-sim">
          <.input
            name="name"
            value=""
            type="text"
            label={gettext("Your name")}
            placeholder={gettext("Enter your name")}
            required
          />
          <.input
            name="code"
            value=""
            type="text"
            label={gettext("Simulation code")}
            placeholder={gettext("Enter the code")}
            autocomplete="off"
            required
          />
          <.button
            id="join-sim-button"
            variant="primary"
            phx-disable-with={gettext("Joining...")}
            class="btn btn-primary w-full"
          >
            {gettext("Join")}
          </.button>
        </form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("join-sim", %{"name" => name, "code" => code}, socket) do
    sim_id = String.to_integer(code)

    case SimServer.simulation?(sim_id) do
      true ->
        :ok = SimServer.add_participant_to_simulation(sim_id, name)
        route = SimServer.route_path(sim_id, name)
        {:noreply, socket |> push_navigate(to: route)}

      false ->
        {:noreply, socket |> put_flash(:error, gettext("There is no simulation for this code"))}
    end
  end
end
