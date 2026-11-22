defmodule EcosimWeb.Sim.MarketLive do
  use EcosimWeb, :live_view

  alias Ecosim.SimServer
  alias Ecosim.Sim.Market.Actor

  alias EcosimWeb.SimLog
  alias EcosimWeb.SimLive.MarketLive.PreparationLive, as: Preparation
  alias EcosimWeb.SimLive.MarketLive.ResultsLive, as: Results
  alias EcosimWeb.SimLive.MarketLive.SimLive, as: Sim

  # TODO: if the mode is one-for-all, allow the user to generate a file with
  # distribution and wt
  # TODO: also allow the user to upload the same file to set the participants correctly.

  @impl true
  def render(assigns) do
    # TODO: check if we can pass @info to preparation
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.market_header mode={@mode} />

      <Preparation.preparation
        :if={@info.step == :preparation}
        sim_id={@sim_id}
      />

      <Sim.sim
        :if={@info.step == :sim}
        info={@info}
        offer_focus_actor_name={@offer_focus_actor_name}
      />

      <Results.result
        :if={@info.step == :result}
        info={@info}
      />
      {inspect(@info)}
    </Layouts.app>
    """
  end

  attr :mode, :atom

  def market_header(assigns) do
    ~H"""
    <.header>
      {gettext("Market")} - ({get_mode(@mode)})
      <:subtitle>
        <.link navigate="https://www.researchgate.net/publication/24106520_An_Experimental_Study_of_Competitive_Market_Behavior">
          {gettext("Based on Vernon Smith's 1962 paper")}
        </.link>
      </:subtitle>
      <:actions>
        <button phx-click="back" class="btn btn-primary">
          <.icon name="hero-arrow-left" class="size-6" />
          {gettext("Back")}
        </button>
      </:actions>
    </.header>
    """
  end

  defp get_mode(:one_for_all), do: gettext("One user for all")
  defp get_mode(:bot), do: gettext("One user with bots")
  defp get_mode(:multi), do: gettext("Multi-user")

  @impl true
  def mount(%{"sim_id" => sim_id}, _session, socket) do
    sim_id = String.to_integer(sim_id)
    if connected?(socket), do: SimServer.monitor_liveview(sim_id)

    SimServer.inspect_sim(sim_id)

    {:ok,
     socket
     |> assign(:client_info, SimLog.client_info(socket))
     |> assign(:sim_id, sim_id)
     |> assign(:mode, SimServer.mode(sim_id))
     |> assign(:info, SimServer.info(sim_id))
     |> assign(:market_model, 1)
     |> assign(:offer_focus_actor_name, nil)}
  end

  @impl true
  def handle_event("back", _, socket) do
    sim_id = socket.assigns.sim_id

    {:ok, info} =
      SimServer.update(sim_id, :step_back, %{})

    {:noreply, socket |> assign(:info, info)}
  end

  # Preparation Events ****************************************************

  def handle_event("user-click-generate-file", _, socket) do
    info = socket.assigns.info
    file = create_file(info.buyers ++ info.sellers)

    {:noreply,
     socket
     |> assign(:actors_file, file)}
  end

  def handle_event("start", _, socket) do
    {:ok, info} = socket.assigns.sim_id |> SimServer.update(:step_forward)

    {:noreply, socket |> assign(:info, info)}
  end

  def handle_event("select-model", %{"model" => market_model}, socket) do
    market_model = String.to_integer(market_model)

    {:ok, info} =
      socket.assigns.sim_id
      |> SimServer.update(:select_model, %{market_model: market_model})

    {:noreply, socket |> assign(:info, info)}
  end

  # Simulation Events ***************************************************

  def handle_event("restart-sim", _, socket) do
    {:ok, info} = socket.assigns.sim_id |> SimServer.update(:restart_sim)
    {:noreply, assign(socket, :info, info) |> assign(:period_index, 0)}
  end

  def handle_event(
        "add-action",
        %{"actor" => action_actor_name, "price" => price},
        %{assigns: %{sim_id: sim_id}} = socket
      ) do
    price =
      case Integer.parse(price) do
        :error -> 0
        {number, _} -> number
      end

    case actor(sim_id, action_actor_name) do
      nil ->
        {:noreply, put_flash(socket, :error, gettext("The given actor does not exist."))}

      actor ->
        case SimServer.update(sim_id, :offer, %{actor: actor, price: price}) do
          {:ok, info} ->
            {:noreply, socket |> assign(:info, info)}

          {:error, :price_not_in_wt} ->
            {:noreply,
             put_flash(
               socket,
               :error,
               gettext(
                 "The given price does not respect the actor's willingness to pay or accept."
               )
             )}
        end
    end
  end

  def handle_event("user-click-offer", %{"offer" => offer}, socket) do
    {:noreply, socket |> assign(:offer_focus_actor_name, offer)}
  end

  def handle_event("user-click-away-from-offer", _, socket) do
    {:noreply, socket |> assign(:offer_focus_actor_name, nil)}
  end

  def handle_event("accept-price", %{"actors-input-seller" => ""}, socket),
    do: {:noreply, socket}

  def handle_event("accept-price", %{"actors-input-buyer" => ""}, socket),
    do: {:noreply, socket}

  def handle_event(
        "accept-price",
        %{"actors-input-seller" => actor, "price" => price},
        socket
      ) do
    sim_id = socket.assigns.sim_id
    seller = actor(sim_id, actor)
    buyer = actor(sim_id, socket.assigns.offer_focus_actor_name)

    handle_accept(sim_id, seller, buyer, price, socket)
  end

  def handle_event(
        "accept-price",
        %{"actors-input-buyer" => actor, "price" => price},
        socket
      ) do
    sim_id = socket.assigns.sim_id
    buyer = actor(sim_id, actor)
    seller = actor(sim_id, socket.assigns.offer_focus_actor_name)

    handle_accept(sim_id, seller, buyer, price, socket)
  end

  def handle_event("undo-last-action", %{}, socket) do
    {:ok, info} =
      SimServer.update(
        socket.assigns.sim_id,
        :undo,
        %{}
      )

    {:noreply,
     assign(
       socket,
       :info,
       info
     )}
  end

  def handle_event("add-period", %{}, socket) do
    {:ok, info} = SimServer.update(socket.assigns.sim_id, :add_period)
    {:noreply, assign(socket, :info, info)}
  end

  def handle_event("show-period", %{"period" => period_index}, socket) do
    period_index = String.to_integer(period_index)

    {:ok, info} =
      socket.assigns.sim_id
      |> SimServer.update(:change_active_period, %{period: period_index})

    {:noreply,
     assign(
       socket,
       :info,
       info
     )}
  end

  def handle_event("finish-sim", _, socket) do
    sim_id = socket.assigns.sim_id

    info =
      with {:ok, info} <- SimServer.update(sim_id, :step_forward) do
        info
      end

    SimLog.log(:result_viewed, socket.assigns.client_info,
      sim: "market",
      mode: socket.assigns.mode
    )

    {:noreply, assign(socket, :step, :result) |> assign(:info, info)}
  end

  # Supporting Functions ********************************************************

  defp parse_price(price) when is_number(price), do: price

  defp parse_price(price) when is_binary(price) do
    case Float.parse(price) do
      {number, _} -> if number == trunc(number), do: trunc(number), else: number
      :error -> 0
    end
  end

  defp handle_accept(
         sim_id,
         %Actor{} = seller,
         %Actor{} = buyer,
         price,
         socket
       ) do
    price = parse_price(price)

    case SimServer.update(
           sim_id,
           :accept,
           %{seller: seller, buyer: buyer, price: price}
         ) do
      {:ok, info} ->
        {:noreply, socket |> assign(:info, info)}

      {:error, :price_not_in_wt} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           gettext("The given price does not respect the actor's willingness to pay or accept.")
         )}
    end
  end

  defp create_file(actors) do
    actors
    |> Enum.map(fn actor ->
      Enum.join([actor_type_to_string(actor.type), actor.name, actor.wt], ",")
    end)
    |> Enum.join("\n")
  end

  defp actor_type_to_string(:buyer), do: gettext("Buyer")
  defp actor_type_to_string(:seller), do: gettext("Seller")

  defp actor(sim_id, look_for_name) do
    %{active_actors: active_actors} = SimServer.info(sim_id)
    Enum.find(active_actors, &(&1.name == look_for_name))
  end
end
