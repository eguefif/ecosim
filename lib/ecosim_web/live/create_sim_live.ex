defmodule EcosimWeb.CreateSimLive do
  use EcosimWeb, :live_view

  # TODO: create the sim_server when sim is choosen.
  # TODO: when push navigate, call unmonitor_liveview
  # TODO: add participants section
  # TODO: update sim when participants

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      {gettext("Create a simulation")}
    </.header>
    <div class="flex flex-col gap-[32px]">
      <ul class="steps">
        <li
          class={[
            "step step-primary",
            numbered_step(@step) >= 2 &&
              "hover:scale-104 duration-200 transform-transition ease-and-out"
          ]}
          phx-click={numbered_step(@step) >= 2 && go("back-to-choose-sim")}
        >
          {gettext("Choose Simulation")}
        </li>
        <li
          class={[
            "step",
            numbered_step(@step) >= 2 &&
              "step-primary hover:scale-104 duration-200 transform-transition ease-and-out"
          ]}
          phx-click={numbered_step(@step) >= 3 && go("back-to-choose-mode")}
        >
          {gettext("Choose Mode")}
        </li>
        <li class={["step", numbered_step(@step) >= 3 && "step-primary"]}>
          {gettext("Add Participants")}
        </li>
      </ul>
      <div id="steps">
        <div :if={@step == :choose_sim} id="step-choose-sim" phx-mounted={step_in()}>
          <.choose_sim sim={@sim} />
        </div>
        <div :if={@step == :choose_mode} id="step-choose-mode" phx-mounted={step_in()}>
          <.choose_mode mode={@mode} />
        </div>
        <div :if={@step == :add_participants} id="step-add-participants" phx-mounted={step_in()}>
          <.add_participants mode={@mode} />
        </div>
      </div>

      <button
        :if={@step != :choose_sim}
        id="back-btn"
        class="btn btn-primary w-[96px] mx-auto"
        phx-click={go("back")}
      >
        {gettext("Back")}
      </button>
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
          phx-click={go("choose-sim", %{sim: "market"})}
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
            "card bg-base-100 w-[256px] h-[192px] shadow-md hover:scale-104 duration-200 transition-transform ease-in-out hover:pointer"
          ]}
          phx-click={go("choose-mode", %{mode: "one-for-all"})}
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
          class="card bg-base-100 w-[256px] h-[192px] shadow-md hover:scale-104 duration-200 transition-transform ease-in-out hover:pointer"
          phx-click={go("choose-mode", %{mode: "multi"})}
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
          class="card bg-base-100 w-[256px] h-[192px] shadow-md hover:scale-104 duration-200 transition-transform ease-in-out hover:pointer"
          phx-click={go("choose-mode", %{mode: "bot"})}
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

  attr :mode, :string

  def add_participants(assigns) do
    ~H"""
    {@mode}
    """
  end

  # defp build_sim_route("market", mode), do: ~p"/sim/market?mode=#{mode}"

  defp step_in do
    JS.transition(
      {"ease-out duration-500", "opacity-0 translate-x-8", "opacity-100 translate-x-0"},
      time: 500
    )
  end

  # Animates the current step out, then sends the event. LiveView holds back
  # the DOM patch until the hide transition finishes, so the next step only
  # appears (and runs its phx-mounted step_in) once the old one is gone.
  defp go(event, value \\ %{}) do
    JS.hide(
      to: "#steps > div",
      transition:
        {"ease-in duration-300", "opacity-100 translate-x-0", "opacity-0 -translate-x-16"},
      time: 300
    )
    |> JS.push(event, value: value)
  end

  defp numbered_step(:choose_sim), do: 1
  defp numbered_step(:choose_mode), do: 2
  defp numbered_step(:add_participants), do: 3

  @impl true
  def mount(_parms, _session, socket) do
    {:ok,
     socket
     |> assign(:step, :choose_sim)
     |> assign(:sim, nil)
     |> assign(:mode, nil)}
  end

  @impl true
  def handle_event("choose-sim", %{"sim" => sim}, socket) do
    {:noreply, socket |> assign(:sim, sim) |> assign(:step, :choose_mode)}
  end

  @impl true
  def handle_event("choose-mode", %{"mode" => mode}, socket) do
    {:noreply, socket |> assign(:mode, mode) |> assign(:step, :add_participants)}
  end

  @impl true
  def handle_event("back", %{}, socket) do
    case socket.assigns.step do
      :add_participants -> {:noreply, socket |> assign(:step, :choose_mode)}
      :choose_mode -> {:noreply, socket |> assign(:step, :choose_sim)}
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def handle_event("back-to-choose-sim", %{}, socket) do
    {:noreply, socket |> assign(:mode, "one_for_all") |> assign(:step, :choose_sim)}
  end

  @impl true
  def handle_event("back-to-choose-mode", %{}, socket) do
    {:noreply, socket |> assign(:step, :choose_mode)}
  end
end
