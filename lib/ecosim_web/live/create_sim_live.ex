defmodule EcosimWeb.CreateSimLive do
  use EcosimWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      {gettext("Create a simulation")}
    </.header>
    <div class="flex flex-col gap-[32px]">
      <.choose_sim sim={@sim} />
      <.choose_mode :if={@sim != nil} mode={@mode} />
      <.link
        :if={@sim != nil && @mode != nil}
        href={build_sim_route(@sim, @mode)}
        class="btn btn-primary mx-auto w-[128px]"
      >{gettext("Start")}</.link>
    </div>
    """
  end

  attr :sim, :string, default: nil

  def choose_sim(assigns) do
    ~H"""
    <div class="flex flex-row gap-[16px]">
      <div class={[@sim == "market" && "aura"]}>
        <div
          class={[
            "card bg-base-100 w-[256px] shadow-md hover:scale-102 hover:pointer transition-transform duration-200 ease-in-out"
          ]}
          phx-click="choose-sim"
          phx-value-sim="market"
        >
          <figure>
            <img src={~p"/images/market-card.jpg"} alt={gettext("Market")} />
          </figure>
          <div class="card-body">
            <h2 class="card-title">
              {gettext("The Market")}
            </h2>
            <p>{gettext("Simulate a market following Vernon Smith's 1962 protocol.")}</p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :mode, :string, default: nil

  def choose_mode(assigns) do
    ~H"""
    <div class="flex flex-row gap-[32px] transform-transition">
      <div class={[@mode == "one-for-all" && "aura"]}>
        <div
          class={[
            "card bg-base-100 w-[256px] h-[192px] shadow-md hover:scale-104 duration-200 transition-transform ease-in-out"
          ]}
          phx-click="choose-mode"
          phx-value-mode="one-for-all"
        >
          <div class="card-body">
            <h2 class="card-title">
              {gettext("One user for all")}
            </h2>
            <p>
              {gettext(
                "In this mode, one user provides the list of economic actors and records every action."
              )}
            </p>
          </div>
        </div>
      </div>

      <div class={[@mode == "multi" && "aura"]}>
        <div
          class="card bg-base-100 w-[256px] h-[192px] shadow-md hover:scale-104 duration-200 transition-transform ease-in-out"
          phx-click="choose-mode"
          phx-value-mode="multi"
        >
          <div class="card-body">
            <h2 class="card-title">
              {gettext("Multi-user")}
            </h2>
            <p>
              {gettext(
                "In this mode, each user uses their own device and joins the simulation with a code."
              )}
            </p>
          </div>
        </div>
      </div>

      <div class={[@mode == "bot" && "aura"]}>
        <div
          class="card bg-base-100 w-[256px] h-[192px] shadow-md hover:scale-104 duration-200 transition-transform ease-in-out"
          phx-click="choose-mode"
          phx-value-mode="bot"
        >
          <div class="card-body">
            <h2 class="card-title">
              {gettext("One user with bots")}
            </h2>
            <p>
              {gettext("In this mode, one user runs the simulation with bots.")}
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp build_sim_route("market", mode), do: ~p"/sim/market?mode=#{mode}"

  @impl true
  def mount(_parms, _session, socket) do
    {:ok,
     socket
     |> assign(:step, :sim)
     |> assign(:sim, nil)
     |> assign(:mode, nil)}
  end

  @impl true
  def handle_event("choose-sim", %{"sim" => sim}, socket) do
    {:noreply, socket |> assign(:sim, sim) |> assign(:step, :mode)}
  end

  @impl true
  def handle_event("choose-mode", %{"mode" => mode}, socket) do
    {:noreply, socket |> assign(:mode, mode) |> assign(:step, :validate)}
  end
end
