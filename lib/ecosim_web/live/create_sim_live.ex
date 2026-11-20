defmodule EcosimWeb.CreateSimLive do
  use EcosimWeb, :live_view

  import EcosimWeb.CreateSimLive.Transitions
  import EcosimWeb.CreateSimLive.ChooseSimComponent
  import EcosimWeb.CreateSimLive.ChooseModeComponent
  import EcosimWeb.CreateSimLive.AddParticipantsComponent

  # TODO: MarketLive must take over the simulation: in mount/3, read
  #   params["sim_id"] and call Ecosim.SimServer.monitor_liveview/1 when
  #   connected?(socket), otherwise the server stops 30 seconds after "start-sim".
  # TODO: add the multi mode
  #     - show the join code
  #     - implement an handle_info on :new_participant_sim from the gen server and retrieve the
  #        participants list, display it.

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      {gettext("Create a simulation")}
    </.header>
    <div class="flex flex-col gap-[32px]">
      <.show_steps_indicator step={@step} />
      <div id="steps">
        <div :if={@step == :choose_sim} id="step-choose-sim" phx-mounted={step_in()}>
          <.choose_sim sim={sim_type(@sim)} />
        </div>
        <div :if={@step == :choose_mode} id="step-choose-mode" phx-mounted={step_in()}>
          <.choose_mode mode={sim_mode(@sim)} />
        </div>
        <div :if={@step == :add_participants} id="step-add-participants" phx-mounted={step_in()}>
          <.add_participants
            mode={sim_mode(@sim)}
            uploads={@uploads}
            participants={@participants}
          />
        </div>
      </div>
      <div class="flex flex-row w-max gap-[32px]">
        <button
          :if={@step != :choose_sim}
          id="back-btn"
          class="btn btn-primary w-[96px] mx-auto"
          phx-click={go("back")}
        >
          {gettext("Back")}
        </button>
        <button
          :if={@step != :choose_sim && @participants != []}
          id="start-sim"
          class="btn btn-secondary w-[96px] mx-auto"
          phx-click="start-sim"
        >
          {gettext("Start")}
        </button>
      </div>
    </div>
    """
  end

  attr :step, :integer, default: 0

  def show_steps_indicator(assigns) do
    ~H"""
    <ul class="steps w-full">
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
    """
  end

  # defp build_sim_route("market", mode), do: ~p"/sim/market?mode=#{mode}"

  defp parse_participants(content) do
    content
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim(&1))
    |> Enum.reject(&(&1 == ""))
  end

  defp numbered_step(:choose_sim), do: 1
  defp numbered_step(:choose_mode), do: 2
  defp numbered_step(:add_participants), do: 3

  defp sim_type(sim) do
    case Ecosim.SimServer.type(sim) do
      nil -> nil
      type when is_atom(type) -> Atom.to_string(type)
    end
  end

  defp sim_mode(sim) do
    case Ecosim.SimServer.mode(sim) do
      nil -> nil
      mode when is_atom(mode) -> Atom.to_string(mode)
    end
  end

  # Mount ***********************************************************************

  @impl true
  def mount(_parms, _session, socket) do
    {:ok, sim} = Ecosim.SimServer.start()

    {:ok,
     socket
     |> assign(:step, :choose_sim)
     |> assign(:sim, sim)
     |> assign(:participants, [])
     |> allow_upload(:participants,
       accept: ~w(.txt .csv),
       max_entries: 1,
       max_file_size: 1_000_000
     )}
  end

  # Events ***********************************************************************

  @impl true
  def handle_event("choose-sim", %{"sim" => sim_type}, socket) do
    :ok = Ecosim.SimServer.set_sim_type(socket.assigns.sim, sim_type)
    {:noreply, socket |> assign(:step, :choose_mode)}
  end

  @impl true
  def handle_event("choose-mode", %{"mode" => mode}, socket) do
    :ok = Ecosim.SimServer.set_sim_mode(socket.assigns.sim, mode)
    {:noreply, socket |> assign(:step, :add_participants)}
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

  @impl true
  def handle_event("remove-participant", %{"participant" => participant}, socket) do
    participants = socket.assigns.participants |> Enum.reject(&(&1 == participant))
    {:noreply, socket |> assign(:participants, participants)}
  end

  def handle_event("start-sim", %{}, socket) do
    sim_id = socket.assigns.sim

    :ok = Ecosim.SimServer.add_participants_to_simulation(sim_id, socket.assigns.participants)
    sim_path = Ecosim.SimServer.route_path(sim_id)

    :ok = Ecosim.SimServer.demonitor_liveview(sim_id)
    :ok = Ecosim.SimServer.create_simulation(sim_id)

    {:noreply, push_navigate(socket, to: sim_path)}
  end

  # Participants upload (one-for-all mode) *********************************

  @impl true
  def handle_event("validate_upload", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :participants, ref)}
  end

  @impl true
  def handle_event("save_upload", _params, socket) do
    content =
      socket
      |> consume_uploaded_entries(:participants, fn %{path: path}, _entry ->
        {:ok, File.read!(path)}
      end)
      |> List.first()

    {:noreply, assign(socket, :participants, parse_participants(content))}
  end
end
