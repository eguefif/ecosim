defmodule EcosimWeb.SimLive.MarketLive.JoinMarketSimLive do
  use EcosimWeb, :live_view

  alias Ecosim.Sim.SimServer
  alias Ecosim.Sim.Market.Actor
  alias EcosimWeb.SimLive.MarketLive.SimLive

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {title(@simulation_status)} - {@name}
      </.header>
      <.waiting_screen :if={@simulation_status == :waiting} />
      <.sim_screen
        :if={@simulation_status == :running}
        info={@info}
        name={@name}
        price_focus={@price_focus}
      />
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

  attr :info, :map
  attr :name, :string
  attr :price_focus, :string

  def sim_screen(assigns) do
    ~H"""
    <div class="flex flex-col gap-[32px]">
      <div class="flex flex-col md:flex-row gap-[8px] items-center">
        <.show_participant_info participant_info={participant_info(@info, @name)} />
        <.show_offer_input active={Enum.any?(@info.active_actors, &(Actor.name(&1) == @name))} />
      </div>
      <.show_market_info
        info={@info}
        participant_type={participant_info(@info, @name) |> Map.get(:type)}
        price_focus={@price_focus}
      />
    </div>
    """
  end

  attr :participant_info, :map

  def show_participant_info(assigns) do
    ~H"""
    <div class="shadow-md rounded-lg flex flex-col gap-[16px] items-center bg-neutral p-[8px] md:p-[16px] w-[128px]">
      <div class="text-xl">{type_to_string(@participant_info.type) |> String.capitalize()}</div>
      <div class="text-3xl">{@participant_info.wt}</div>
    </div>
    """
  end

  attr :active, :boolean, default: true

  def show_offer_input(assigns) do
    ~H"""
    <form
      id="participant-offer-price"
      phx-submit="make-offer"
      class="flex flex-col md:flex-row gap-[8px] w-full items-center md:items-baseline"
    >
      <.input
        class="w-[128px] input"
        disabled={@active == false}
        type="text"
        value=""
        name="offer-input"
      />
      <button type="submit" class="btn btn-primary">{gettext("Make Offer")}</button>
    </form>
    """
  end

  attr :info, :map
  attr :participant_type, :string
  attr :price_focus, :string

  def show_market_info(assigns) do
    ~H"""
    <div class="flex flex-col gap-[16px]">
      <div :if={@participant_type == :buyer} class="text-lg font-bold mx-auto">
        {gettext("Sellers")}
      </div>
      <div :if={@participant_type == :seller} class="text-lg font-bold">
        {gettext("Buyers")}
      </div>
      <.show_offers
        :if={@participant_type == :buyer}
        offers={@info.sellers}
        type="seller"
        price_focus={@price_focus}
      />
      <.show_offers
        :if={@participant_type == :seller}
        offers={@info.buyers}
        type="buyer"
        price_focus={@price_focus}
      />

      <div class="flex flex-row gap-[8px]">
        <div class="divider"></div>
        <SimLive.show_transactions transactions={@info.transactions} />
        <div class="divider divider-horizontal"></div>

        <div class="flex flex-col items-center">
          <div :if={@participant_type == :buyer} class="text-lg font-bold">{gettext("Buyers")}</div>
          <div :if={@participant_type == :seller} class="text-lg font-bold">
            {gettext("Sellers")}
          </div>
          <div class="divider"></div>
          <.show_offers_secondary
            :if={@participant_type == :buyer}
            offers={@info.buyers}
            type="buyer"
          />
          <.show_offers_secondary
            :if={@participant_type == :seller}
            offers={@info.sellers}
            type="seller"
          />
        </div>
      </div>
    </div>
    """
  end

  attr :offers, :list
  attr :type, :string
  attr :price_focus, :string

  def show_offers(assigns) do
    ~H"""
    <div id={"#{@type}-offers"} class="flex flex-row flex-wrap gap-[8px]">
      <%!-- Fixed-size slot: it keeps its place in the layout while the card
           inside floats above it, so scaling or expanding never moves siblings. --%>
      <div :for={offer <- @offers} class="relative w-[74px] h-[44px]">
        <div
          class={[
            "absolute inset-x-0 top-0 min-h-full origin-top cursor-pointer",
            "flex flex-col items-center justify-center rounded-lg py-[4px] px-[8px] text-center",
            "transition-all duration-200 ease-in-out",
            @type == "buyer" && "bg-seller",
            @type == "seller" && "bg-buyer",
            if(@price_focus == offer.name,
              do: "scale-120 z-20 shadow-xl",
              else: "shadow-md hover:scale-110 hover:z-10"
            )
          ]}
          phx-click="focus-price"
          phx-click-away="remove-focus-price"
          phx-value-offer-name={offer.name}
        >
          <span class="w-full truncate">{offer.name}</span>
          <span class="w-full font-weight">{offer.price}</span>
          <%!-- Always rendered so it can slide open/closed instead of popping in --%>
          <div class={[
            "grid w-full transition-all duration-200 ease-in-out",
            if(@price_focus == offer.name,
              do: "grid-rows-[1fr] opacity-100 mt-[4px]",
              else: "grid-rows-[0fr] opacity-0 invisible"
            )
          ]}>
            <div class="overflow-hidden flex justify-center">
              <button
                type="button"
                class="btn btn-secondary btn-xs"
                phx-click="accept"
                phx-value-offer-name={offer.name}
                phx-value-offer-price={offer.price}
              >
                <.icon name="hero-check" class="size-4" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :offers, :list
  attr :type, :string

  def show_offers_secondary(assigns) do
    ~H"""
    <div class="flex flex-col flex-wrap gap-[8px]">
      <div
        :for={offer <- @offers}
        class={[
          "shadow-md rounded-lg py-[4px] px-[8px] w-[74px] text-center text-ellipsis",
          @type == "buyer" && "bg-seller",
          @type == "seller" && "bg-buyer"
        ]}
      >
        {offer.name}
      </div>
    </div>
    """
  end

  attr :transactions, :list

  def show_transactionss(assigns) do
    ~H"""
    <div class="flex flex-col w-full items-center">
      <div class="flex flex-row md:flex-col gap-[8px]">
        <div
          :for={
            %{seller: seller, buyer: buyer, price: price} <-
              @transactions
          }
          class="bg-transaction shadow-md p-[16px] rounded-lg"
        >
          {SimLive.transaction_text(seller, buyer, price)}
        </div>
      </div>
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

  defp participant_info(info, name) do
    IO.inspect(info)
    participant = Enum.find(info.actors, &(Actor.name(&1) == name))

    %{
      type: participant.type,
      wt: participant.wt,
      name: participant.name
    }
  end

  def title(:waiting), do: gettext("Welcome to this simulation")
  def title(:running), do: gettext("Market is opened")
  def title(:results), do: gettext("Results")

  def type_to_string(:buyer), do: gettext("buyer")
  def type_to_string(:seller), do: gettext("seller")

  @impl true
  def mount(%{"sim_id" => sim_id, "name" => name} = _, _session, socket) do
    sim_id = String.to_integer(sim_id)

    {status, info} =
      if SimServer.simulation?(sim_id) do
        if connected?(socket), do: join_simulation(sim_id, name)
        info = SimServer.info(sim_id)
        {step_to_status(info.step), info}
      else
        {:finished, nil}
      end

    {:ok,
     socket
     |> assign(:name, name)
     |> assign(:wt, nil)
     |> assign(:info, info)
     |> assign(:sim_id, sim_id)
     |> assign(:price_focus, nil)
     |> assign(:simulation_status, status)}
  end

  @impl true
  def handle_event("make-offer", %{"offer-input" => offer}, socket) do
    price = String.to_integer(offer)
    info = socket.assigns.info
    name = socket.assigns.name
    sim_id = socket.assigns.sim_id

    case SimServer.update(sim_id, :offer, %{actor: actor(info, name), price: price}) do
      {:ok, _} ->
        {:noreply, socket}

      {:error, :price_not_in_wt} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           gettext("The given price does not respect the actor's willingness to pay or accept.")
         )}
    end
  end

  def handle_event("accept", %{"offer-name" => name, "offer-price" => price}, socket) do
    price = String.to_integer(price)
    params = accept_update_params(socket.assigns.name, name, price, socket.assigns.info)
    sim_id = socket.assigns.sim_id

    case SimServer.update(sim_id, :accept, params) do
      {:ok, _} ->
        {:noreply, socket |> assign(:price_focus, nil)}

      {:error, :price_not_in_wt} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           gettext("The given price does not respect the actor's willingness to pay or accept.")
         )}
    end
  end

  def handle_event("focus-price", %{"offer-name" => name}, socket) do
    {:noreply, socket |> assign(:price_focus, name)}
  end

  def handle_event("remove-focus-price", %{}, socket) do
    {:noreply, socket |> assign(:price_focus, nil)}
  end

  defp accept_update_params(name1, name2, price, info) do
    actor1 = actor(info, name1)
    actor2 = actor(info, name2)

    case {Actor.type(actor1), Actor.type(actor2)} do
      {:seller, :buyer} -> %{seller: actor1, buyer: actor2, price: price}
      {:buyer, :seller} -> %{buyer: actor1, seller: actor2, price: price}
    end
  end

  defp actor(info, name) do
    Enum.find(info.active_actors, &(&1.name == name))
  end

  # Only from the connected mount: the disconnected render runs in a short-lived
  # process whose :DOWN would remove the participant right after joining.
  # The participant is added again if missing, e.g. when the page is opened
  # directly from its URL or after a reload removed it.
  defp join_simulation(sim_id, name) do
    unless name in SimServer.sim_participants(sim_id) do
      :ok = SimServer.add_participant_to_simulation(sim_id, name)
    end

    SimServer.subscribe(sim_id)
    SimServer.monitor_participant_liveview(sim_id, name)
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

    {:noreply,
     socket
     |> assign(:info, info)
     |> assign(:simulation_status, step_to_status(info.step))}
  end

  def handle_info(:new_participants, socket) do
    {:noreply, socket}
  end

  def handle_info(:remove_participant, socket) do
    {:noreply, socket}
  end

  defp step_to_status(:preparation), do: :waiting
  defp step_to_status(:sim), do: :running
  defp step_to_status(:result), do: :finished
end
