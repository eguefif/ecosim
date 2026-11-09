defmodule EcosimWeb.Sim.MarketLive do
  use EcosimWeb, :live_view

  alias EcosimWeb.SimLive.OneForAllModeLive, as: OneMode
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
            {gettext("Based on Veron Smith 1962 paper")}
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
      />

      <OneMode.sim :if={@step == :sim} market={@market} period_index={@period_index} />

      <CommonLive.result :if={@step == :result} graph={@graph} />
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
     |> assign(:step, :preparation)
     |> assign(:actors, [])
     |> allow_upload(:actors,
       accept: ~w(.txt .csv),
       max_entries: 1,
       max_file_size: 1_000_000
     )}
  end

  @impl true
  def handle_event("start", _, socket) do
    actors =
      socket.assigns.actors
      |> Enum.map(&Actor.new/1)

    buyers = actors |> Enum.filter(&(&1.type == :buyer))
    sellers = actors |> Enum.filter(&(&1.type == :seller))
    market = Market.new(buyers, sellers)

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
      |> IO.inspect()
      |> make_graph(gettext("Price evolution per transaction"))

    {:noreply, assign(socket, :step, :result) |> assign(:graph, graph)}
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

  def handle_event(
        "accept-price",
        %{"actors-input-seller" => actor},
        socket
      ) do
    market = socket.assigns.market
    period_index = socket.assigns.period_index
    actor = Market.actor(market, actor)

    case Market.update(market, :accept, %{actor: actor}, period_index) do
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

  def handle_event(
        "accept-price",
        %{"actors-input-buyer" => actor},
        socket
      ) do
    market = socket.assigns.market
    period_index = socket.assigns.period_index
    actor = Market.actor(market, actor)

    case Market.update(market, :accept, %{actor: actor}, period_index) do
      {:ok, market} ->
        {:noreply, socket |> assign(:market, market)}

      {:error, error} ->
        IO.inspect(error)
        {:noreply, socket |> put_flash(:error, gettext("Error"))}
    end
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
    |> String.split("\n", trim: true)
    |> Enum.map(&(String.split(&1, ",") |> Enum.map(fn entry -> String.trim(entry) end)))
  end

  # TODO: remove with the hardcoded test data in `mount/3`.
  # Builds a market with 4 periods. WTA: Alice 12, Bruno 15, Chloé 20.
  # WTB: David 25, Émilie 18, François 10. Theoretical equilibrium: 2 transactions
  # at a price between 15 and 18. Prices are dispersed in period 1 and converge to 16.
  defp build_test_market do
    buyers = [
      Actor.new(:buyer, "David", 25),
      Actor.new(:buyer, "Émilie", 18),
      Actor.new(:buyer, "François", 10)
    ]

    sellers = [
      Actor.new(:seller, "Alice", 12),
      Actor.new(:seller, "Bruno", 15),
      Actor.new(:seller, "Chloé", 20)
    ]

    # periods = [
    #  # Period 1: David accepts Bruno at 20, Alice accepts Émilie at 17
    #  [
    #    {:offer, "Alice", 22},
    #    {:offer, "David", 14},
    #    {:offer, "Bruno", 20},
    #    {:accept, "David"},
    #    {:offer, "Émilie", 15},
    #    {:offer, "Alice", 19},
    #    {:offer, "Émilie", 17},
    #    {:accept, "Alice"},
    #    {:offer, "Chloé", 24},
    #    {:offer, "François", 8},
    #    {:offer, "Chloé", 22},
    #    {:offer, "François", 10}
    #  ],
    #  # Period 2: David accepts Alice at 17, Émilie accepts Bruno at 17
    #  [
    #    {:offer, "Bruno", 19},
    #    {:offer, "Émilie", 14},
    #    {:offer, "Alice", 18},
    #    {:offer, "David", 16},
    #    {:offer, "Alice", 17},
    #    {:accept, "David"},
    #    {:offer, "Émilie", 15},
    #    {:offer, "Bruno", 17},
    #    {:accept, "Émilie"},
    #    {:offer, "Chloé", 22},
    #    {:offer, "François", 10}
    #  ],
    #  # Period 3: Bruno accepts Émilie at 16, Alice accepts David at 16
    #  [
    #    {:offer, "David", 15},
    #    {:offer, "Bruno", 18},
    #    {:offer, "Émilie", 16},
    #    {:accept, "Bruno"},
    #    {:offer, "Alice", 17},
    #    {:offer, "David", 16},
    #    {:accept, "Alice"},
    #    {:offer, "Chloé", 21},
    #    {:offer, "François", 9}
    #  ],
    #  # Period 4: Émilie accepts Bruno at 16, Alice accepts David at 16
    #  [
    #    {:offer, "Alice", 17},
    #    {:offer, "Émilie", 16},
    #    {:offer, "Bruno", 16},
    #    {:accept, "Émilie"},
    #    {:offer, "David", 16},
    #    {:accept, "Alice"},
    #    {:offer, "Chloé", 20},
    #    {:offer, "François", 10}
    #  ]
    # ]

    # periods
    # |> Enum.with_index()
    # |> Enum.reduce(Market.new(buyers, sellers), fn {actions, index}, market ->
    #  market =
    #    if index == 0 do
    #      market
    #    else
    #      {:ok, market} = Market.update(market, :add_period)
    #      market
    #    end

    #  Enum.reduce(actions, market, &apply_test_action/2)
    # end)
    Market.new(buyers, sellers)
  end

  # defp apply_test_action({:offer, name, price}, market) do
  #  {:ok, market} =
  #    Market.update(market, :offer, %{actor: Market.actor(market, name), price: price})

  #  market
  # end

  # defp apply_test_action({:accept, name}, market) do {:ok, market} = Market.update(market, :accept, %{actor: Market.actor(market, name)})
  #  market
  # end

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
end
