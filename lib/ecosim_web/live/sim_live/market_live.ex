defmodule EcosimWeb.Sim.MarketLive do
  use EcosimWeb, :live_view

  alias Ecosim.Sim.Market
  alias Ecosim.Sim.Market.Actor

  alias EcosimWeb.SimLog
  alias EcosimWeb.SimLive.MarketLive.PreparationLive, as: Preparation
  alias EcosimWeb.SimLive.MarketLive.ResultsLive, as: Results
  alias EcosimWeb.SimLive.MarketLive.SimLive, as: Sim

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.market_header mode={@mode} />

      <Preparation.preparation
        :if={@market.step == :preparation}
        mode={@mode}
        uploads={@uploads}
        market={@market}
        actors={@actors}
        actors_file={@actors_file}
        join_code={3_123_124}
      />

      <Sim.sim
        :if={@market.step == :sim}
        market={@market}
        offer_focus_actor_name={@offer_focus_actor_name}
      />

      <Results.result
        :if={@market.step == :result}
        market={@market}
      />
      {inspect(@market.periods)}
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

  defp get_mode("one-for-all"), do: gettext("One user for all")
  defp get_mode("bot"), do: gettext("One user with bots")
  defp get_mode("multi"), do: gettext("Multi-user")

  @impl true
  def mount(%{"mode" => mode}, _session, socket) do
    # market = Market.new([], [], 1)
    market = build_test_market(with_history: true)
    {:ok, market} = Market.update(market, :step_forward)

    # join_code = if mode == "multi", do: :rand.uniform(10000), else: nil
    # :ets.insert(:sim_registry, {join_code, "market"})

    {:ok,
     socket
     |> assign(:mode, mode)
     |> assign(:client_info, SimLog.client_info(socket))
     |> assign(:market, market)
     |> assign(:actors_file, nil)
     |> assign(:actors, [])
     |> assign(:market_model, 1)
     |> assign(:offer_focus_actor_name, nil)
     |> allow_upload(:actors,
       accept: ~w(.txt .csv),
       max_entries: 1,
       max_file_size: 1_000_000
     )}
  end

  @impl true
  def handle_event("back", _, socket) do
    market = socket.assigns.market

    socket =
      case Market.update(market, :step_back) do
        {:back_to_start, _} -> socket |> push_navigate(to: ~p"/create-sim")
        {:ok, market} -> assign(socket, :market, market)
      end

    {:noreply, socket}
  end

  # Preparation Events ****************************************************

  def handle_event("user-click-generate-file", _, socket) do
    market = Market.new(socket.assigns.actors, socket.assigns.market_model)

    file = create_file(market.buyers ++ market.sellers)

    {:noreply,
     socket
     |> assign(:actors_file, file)
     |> assign(:market, market)
     |> assign(:period_index, 0)}
  end

  def handle_event("start", _, socket) do
    IO.puts("HEY")
    IO.inspect(socket.assigns.market)
    {:ok, market} = socket.assigns.market |> Market.update(:step_forward)
    IO.inspect(market)

    {:noreply,
     assign(socket, :step, :sim)
     |> assign(:market, market)
     |> assign(:period_index, 0)}
  end

  def handle_event("select-model", %{"model" => market_model}, socket) do
    market_model = String.to_integer(market_model)

    {:ok, market} =
      socket.assigns.market |> Market.update(:select_model, %{market_model: market_model})

    {:noreply, socket |> assign(:market, market)}
  end

  def handle_event("user-click-default-button", %{}, socket) do
    {:ok, market} = build_test_market() |> Market.update(:step_forward)

    log_sim_started(socket, market, :example)

    {:noreply,
     socket
     |> assign(:market, market)}
  end

  def handle_event("validate_upload", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :actors, ref)}
  end

  def handle_event("save_upload", _params, socket) do
    content =
      socket
      |> consume_uploaded_entries(:actors, fn %{path: path}, _entry ->
        {:ok, File.read!(path)}
      end)
      |> List.first()

    actors = parse_content(content)

    {:noreply, assign(socket, :actors, actors)}
  end

  # Simulation Events ***************************************************

  def handle_event("restart-sim", _, socket) do
    market = Market.new(socket.assigns.market)
    {:noreply, assign(socket, :market, market) |> assign(:period_index, 0)}
  end

  def handle_event(
        "add-action",
        %{"actor" => action_actor_name, "price" => price},
        %{assigns: %{market: market}} = socket
      ) do
    price =
      case Integer.parse(price) do
        :error -> 0
        {number, _} -> number
      end

    case actor(market, action_actor_name) do
      nil ->
        {:noreply, put_flash(socket, :error, gettext("The given actor does not exist."))}

      actor ->
        case Market.update(market, :offer, %{actor: actor, price: price}) do
          {:ok, market} ->
            {:noreply, socket |> assign(:market, market)}

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
    market = socket.assigns.market
    seller = actor(market, actor)
    buyer = actor(market, socket.assigns.offer_focus_actor_name)

    handle_accept(market, seller, buyer, price, socket)
  end

  def handle_event(
        "accept-price",
        %{"actors-input-buyer" => actor, "price" => price},
        socket
      ) do
    market = socket.assigns.market
    buyer = actor(market, actor)
    seller = actor(market, socket.assigns.offer_focus_actor_name)

    handle_accept(market, seller, buyer, price, socket)
  end

  def handle_event("undo-last-action", %{}, socket) do
    {:ok, market} =
      Market.update(
        socket.assigns.market,
        :undo
      )

    {:noreply,
     assign(
       socket,
       :market,
       market
     )}
  end

  def handle_event("add-period", %{}, socket) do
    {:ok, market} = Market.update(socket.assigns.market, :add_period)
    {:noreply, assign(socket, :market, market)}
  end

  def handle_event("show-period", %{"period" => period_index}, socket) do
    period_index = String.to_integer(period_index)

    {:ok, market} =
      socket.assigns.market |> Market.update(:change_active_period, %{period: period_index})

    {:noreply,
     assign(
       socket,
       :market,
       market
     )}
  end

  def handle_event("finish-sim", _, socket) do
    {results_info, market} =
      with {:ok, market} <- Market.update(socket.assigns.market, :step_forward),
           results_info <- Market.info(market) do
        {results_info, market}
      end

    SimLog.log(:result_viewed, socket.assigns.client_info,
      sim: "market",
      mode: socket.assigns.mode,
      periods: length(socket.assigns.market.periods),
      transactions: length(results_info.price_per_transaction_plot)
    )

    {:noreply,
     assign(socket, :step, :result)
     |> assign(:market, market)}
  end

  # Supporting Functions ********************************************************

  defp log_sim_started(socket, market, source) do
    SimLog.log(:started, socket.assigns.client_info,
      sim: "market",
      mode: socket.assigns.mode,
      source: source,
      buyers: length(market.buyers),
      sellers: length(market.sellers)
    )
  end

  defp parse_content(content) do
    content
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim(&1))
    |> Enum.reject(&(&1 == ""))
  end

  # Builds the example market.
  #
  # Options:
  #   * `:with_history` - when `true`, the market is filled with several periods
  #     containing offers and transactions. Useful to test the results page.
  defp build_test_market(opts \\ []) do
    actors = ["Alice", "Bruno", "Chloé", "David", "Émilie", "François"]
    market = Market.new(actors, 1)

    if Keyword.get(opts, :with_history, false) do
      {:ok, market} = Market.update(market, :step_forward)
      add_test_history(market)
    else
      market
    end
  end

  # Buyers: Alice (102), Bruno (100), Chloé (98)
  # Sellers: David (98), Émilie (100), François (102)
  defp add_test_history(market) do
    periods = [
      [
        {:offer, "Alice", 96},
        {:offer, "David", 104},
        {:offer, "Alice", 99},
        {:offer, "David", 101},
        {:accept, "David", "Alice", 101},
        {:offer, "Bruno", 97},
        {:offer, "Émilie", 103},
        {:accept, "Émilie", "Bruno", 100},
        {:offer, "Chloé", 95},
        {:offer, "François", 105}
      ],
      [
        {:offer, "Bruno", 98},
        {:offer, "David", 101},
        {:accept, "David", "Bruno", 99},
        {:offer, "Alice", 99},
        {:offer, "Émilie", 101},
        {:accept, "Émilie", "Alice", 100},
        {:offer, "Chloé", 97},
        {:offer, "François", 103}
      ],
      [
        {:offer, "Chloé", 97},
        {:offer, "David", 99},
        {:accept, "David", "Chloé", 98},
        {:offer, "Alice", 100},
        {:offer, "Émilie", 100},
        {:accept, "Émilie", "Alice", 100},
        {:offer, "Bruno", 99},
        {:offer, "François", 102}
      ]
    ]

    periods
    |> Enum.reduce(market, fn actions, market ->
      market = Enum.reduce(actions, market, &apply_test_action(&2, &1))
      {:ok, market} = Market.update(market, :add_period)
      market
    end)
  end

  defp apply_test_action(market, {:offer, name, price}) do
    actor = actor(market, name)
    {:ok, market} = Market.update(market, :offer, %{actor: actor, price: price})
    market
  end

  defp apply_test_action(market, {:accept, seller, buyer, price}) do
    params = %{
      seller: actor(market, seller),
      buyer: actor(market, buyer),
      price: price
    }

    {:ok, market} = Market.update(market, :accept, params)
    market
  end

  defp parse_price(price) when is_number(price), do: price

  defp parse_price(price) when is_binary(price) do
    case Float.parse(price) do
      {number, _} -> if number == trunc(number), do: trunc(number), else: number
      :error -> 0
    end
  end

  # @spec handle_accept(Market.t(), Actor.t(), Actor.t(), number(), integer()) :: {:noreply, }
  defp handle_accept(
         %Market{} = market,
         %Actor{} = seller,
         %Actor{} = buyer,
         price,
         socket
       ) do
    price = parse_price(price)

    case Market.update(
           market,
           :accept,
           %{seller: seller, buyer: buyer, price: price}
         ) do
      {:ok, market} ->
        {:noreply, socket |> assign(:market, market)}

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

  defp actor(%Market{} = market, look_for_name) do
    %{active_actors: active_actors} = Market.info(market)
    Enum.find(active_actors, &(&1.name == look_for_name))
  end
end
