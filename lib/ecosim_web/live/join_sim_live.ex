defmodule EcosimWeb.JoinSimLive do
  use EcosimWeb, :live_view

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
    case :ets.lookup(:sim_registry, code |> String.to_integer()) do
      [{_, route}] ->
        {:noreply, socket |> push_navigate(to: create_path(route, code, name))}

      [] ->
        {:noreply, socket |> put_flash(:error, gettext("There is no simulation for this code"))}
    end
  end

  defp create_path("market", code, name), do: ~p"/sim/join-market?name=#{name}&code=#{code}"
end
