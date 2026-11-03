defmodule EcosimWeb.CreateSimLive do
  use EcosimWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Create Sim
    </.header>
    <div class="flex flex-col gap-[32px]">
      <.choose_sim sim={@sim} />
      <.choose_mode :if={@sim != nil} mode={@mode} />
      <.link
        :if={@sim != nil && @mode != nil}
        href={build_sim_route(@sim, @mode)}
        class="btn btn-primary mx-auto w-[128px]"
      >Commencer</.link>
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
            <img src={~p"/images/market-card.jpg"} alt="Marché" />
          </figure>
          <div class="card-body">
            <h2 class="card-title">
              Le Marché
            </h2>
            <p>Simuler un marché selon le protocol de Veron Smith de 1962.</p>
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
              Un utilisateur pour tous
            </h2>
            <p>
              Dans ce mode, un utilisateur fournit une liste de participants et s'occupe d'enregistrer
              toutes les actions.
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
              Multi utilisateur
            </h2>
            <p>
              Dans ce mode, les utilisateurs utilisent leur propre terminal et rejoingne la simulation avec un code
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
              Un utilisateur avec bots
            </h2>
            <p>
              Dans ce mode, un utilisateur fait la simulation avec des bots.
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
