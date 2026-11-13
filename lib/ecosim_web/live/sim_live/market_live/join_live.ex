defmodule EcosimWeb.Sim.MarketLive.JoinLive do
  use EcosimWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {gettext("Waiting for the simulation to start")}
      </.header>
      <p>
        {@code}
      </p>
      <p>
        {@name}
      </p>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"code" => code, "name" => name}, _session, socket) do
    {:ok,
     socket
     |> assign(:code, code)
     |> assign(:name, name)}
  end
end
