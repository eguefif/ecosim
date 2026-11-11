defmodule EcosimWeb.Sim.MarketLive do
  use EcosimWeb, :live_view

  alias EcosimWeb.SimLive.Market.CommonLive
  alias Ecosim.Sim.Market
  alias Ecosim.Sim.Market.Actor
  alias EcosimWeb.SimLog

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
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

      <CommonLive.preparation
        :if={@step == :preparation}
        mode={@mode}
        uploads={@uploads}
        actors={@actors}
        market_model={@market_model}
      />

      <CommonLive.sim
        :if={@step == :sim}
        market={@market}
        period_index={@period_index}
        offer_focus_actor_name={@offer_focus_actor_name}
      />

      <CommonLive.result
        :if={@step == :result}
        result_graph={@result_graph}
        market_graph={@market_graph}
      />
      <div class="divider p-24"></div>
      <pre :if={@step in [:sim, :result]}>
      {inspect(@market , pretty: true)}
      </pre>
    </Layouts.app>
    """
  end

  defp get_mode("one-for-all"), do: gettext("One user for all")
  defp get_mode("bot"), do: gettext("One user with bots")
  defp get_mode("multi"), do: gettext("Multi-user")

  @impl true
  def mount(%{"mode" => mode}, _session, socket) do
    {:ok,
     socket
     |> assign(:mode, mode)
     |> assign(:client_info, SimLog.client_info(socket))
     |> assign(:step, :sim)
     |> assign(:market, build_test_market())
     |> assign(:period_index, 0)
     |> assign(:actors, [])
     |> assign(:market_model, 1)
     |> assign(:offer_focus_actor_name, nil)
     |> allow_upload(:actors,
       accept: ~w(.txt .csv),
       max_entries: 1,
       max_file_size: 1_000_000
     )}
  end

  def handle_event("user-click-offer", %{"offer" => offer}, socket) do
    {:noreply, socket |> assign(:offer_focus_actor_name, offer)}
  end

  def handle_event("user-click-away-from-offer", _, socket) do
    {:noreply, socket |> assign(:offer_focus_actor_name, nil)}
  end

  def handle_event("select-model", %{"model" => market_model}, socket) do
    market_model = String.to_integer(market_model)
    {:noreply, socket |> assign(:market_model, market_model)}
  end

  @impl true
  def handle_event("start", _, socket) do
    market = Market.new(socket.assigns.actors, socket.assigns.market_model)
    IO.inspect(market)

    log_sim_started(socket, market, :upload)

    {:noreply,
     assign(socket, :step, :sim)
     |> assign(:market, market)
     |> assign(:period_index, 0)}
  end

  def handle_event("back", _, socket) do
    socket =
      case socket.assigns.step do
        :preparation -> socket |> push_navigate(to: ~p"/create-sim")
        :sim -> assign(socket, :step, :preparation)
        :result -> assign(socket, :step, :sim)
      end

    {:noreply, socket}
  end

  def handle_event("finish-sim", _, socket) do
    results = Market.results(socket.assigns.market)

    SimLog.log(:result_viewed, socket.assigns.client_info,
      sim: "market",
      mode: socket.assigns.mode,
      periods: length(socket.assigns.market.periods),
      transactions: length(results)
    )

    graph =
      results
      |> Enum.map(fn %{x: x, y: y} -> [x, y] end)
      |> make_graph(gettext("Price evolution per transaction"))

    market_graph =
      make_market_graph(socket.assigns.market.buyers ++ socket.assigns.market.sellers)

    {:noreply,
     assign(socket, :step, :result)
     |> assign(:result_graph, graph)
     |> assign(:market_graph, market_graph)}
  end

  def handle_event("restart-sim", _, socket) do
    market = Market.new(socket.assigns.market)
    {:noreply, assign(socket, :market, market) |> assign(:period_index, 0)}
  end

  def handle_event(
        "add-action",
        %{"actor" => actor, "price" => price},
        %{assigns: %{market: market, period_index: period_index}} = socket
      ) do
    price =
      case Integer.parse(price) do
        :error -> 0
        {number, _} -> number
      end

    case Market.actor(market, actor) do
      nil ->
        {:noreply, put_flash(socket, :error, gettext("The given actor does not exist."))}

      actor ->
        case Market.update(market, :offer, %{actor: actor, price: price}, period_index) do
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
    period_index = socket.assigns.period_index
    seller = Market.actor(market, actor)
    buyer = Market.actor(market, socket.assigns.offer_focus_actor_name)

    handle_accept(market, seller, buyer, price, period_index, socket)
  end

  def handle_event(
        "accept-price",
        %{"actors-input-buyer" => actor, "price" => price},
        socket
      ) do
    market = socket.assigns.market
    period_index = socket.assigns.period_index
    buyer = Market.actor(market, actor)
    seller = Market.actor(market, socket.assigns.offer_focus_actor_name)

    handle_accept(market, seller, buyer, price, period_index, socket)
  end

  def handle_event("user-click-default-button", %{}, socket) do
    market = build_test_market()

    log_sim_started(socket, market, :example)

    {:noreply,
     socket
     |> assign(:market, market)
     |> assign(:step, :sim)
     |> assign(:period_index, 0)}
  end

  def handle_event("undo-last-action", %{}, socket) do
    {:noreply,
     assign(
       socket,
       :market,
       Market.undo(
         socket.assigns.market,
         socket.assigns.period_index
       )
     )}
  end

  def handle_event("add-period", %{}, socket) do
    {:ok, market} = Market.update(socket.assigns.market, :add_period)
    current_period_index = length(market.periods) - 1
    {:noreply, assign(socket, :market, market) |> assign(:period_index, current_period_index)}
  end

  def handle_event("show-period", %{"period" => period_index}, socket) do
    period_index = String.to_integer(period_index)
    {:noreply, assign(socket, :period_index, period_index)}
  end

  def handle_event("show-day", %{"period" => period}, socket) do
    {:noreply, assign(socket, :period_index, period)}
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
  end

  defp build_test_market do
    actors = ["Alice", "Bruno", "Chloé", "David", "Émilie", "François"]

    Market.new(actors, 1)
  end

  defp make_graph(data, _) when data == [], do: nil

  defp make_graph(data, title) when length(data) != 0 do
    dataset = Contex.Dataset.new(data, ["x", "y"])
    max_price = data |> Enum.map(fn [_x, y] -> y end) |> Enum.max()
    min_price = data |> Enum.map(fn [_x, y] -> y end) |> Enum.min()

    y_scale =
      Contex.ContinuousLinearScale.new()
      |> Contex.ContinuousLinearScale.domain(max(min_price - 5, 0), max(max_price, 1))

    chart = Contex.LinePlot.new(dataset, custom_y_scale: y_scale)

    Contex.Plot.new(600, 400, chart)
    |> Contex.Plot.titles(title, "")
    |> Contex.Plot.to_svg()
  end

  defp parse_price(price) when is_number(price), do: price

  defp parse_price(price) when is_binary(price) do
    case Float.parse(price) do
      {number, _} -> if number == trunc(number), do: trunc(number), else: number
      :error -> 0
    end
  end

  defp make_market_graph(_actors) do
    nil
  end

  # @spec handle_accept(Market.t(), Actor.t(), Actor.t(), number(), integer()) :: {:noreply, }
  defp handle_accept(
         %Market{} = market,
         %Actor{} = seller,
         %Actor{} = buyer,
         price,
         period_index,
         socket
       ) do
    price = parse_price(price)

    case Market.update(
           market,
           :accept,
           %{seller: seller, buyer: buyer, price: price},
           period_index
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
end
