defmodule EcosimWeb.Sim.MarketLive do
  use EcosimWeb, :live_view

  alias EcosimWeb.SimLive.OneForAllModeLive, as: OneMode
  alias EcosimWeb.SimLive.Market.CommonLive
  alias Ecosim.Sim.Market
  alias Ecosim.Sim.Market.Actor

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Market - ({get_mode(@mode)})
        <:subtitle :if={@step == :preparation}>1 - Préparation</:subtitle>
        <:subtitle :if={@step == :sim}>2 - Simulation</:subtitle>
        <:subtitle :if={@step == :result}>3 - Result</:subtitle>
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

  defp get_mode("one-for-all"), do: "Un utilisateur pour tous"
  defp get_mode("bot"), do: "Utilisateur avec bot"
  defp get_mode("multi"), do: "Multi utilisateur"

  @impl true
  def mount(%{"mode" => mode}, _session, socket) do
    # TODO: remove hardcoded test data, restore `:preparation` step and empty actors
    actors = [
      ["vendeur", "Alice", "12"],
      ["vendeur", "Bruno", "15"],
      ["vendeur", "Chloé", "20"],
      ["acheteur", "David", "25"],
      ["acheteur", "Émilie", "18"],
      ["acheteur", "François", "10"]
    ]

    market = build_test_market()
    results = Market.results(market)

    {:ok,
     socket
     |> assign(:mode, mode)
     |> assign(:step, :result)
     |> assign(:market, market)
     |> assign(
       :graph,
       results
       |> Enum.map(fn %{x: x, y: y} -> [x, y] end)
       |> make_graph("Evolution du prix par transaction")
     )
     |> assign(:period_index, 0)
     |> assign(:actors, actors)
     |> allow_upload(:actors,
       accept: ~w(.txt .csv),
       max_entries: 1,
       max_file_size: 1_000_000
     )}
  end

  @impl true
  def handle_event("start", _, socket) do
    buyers = socket.assigns.actors |> Enum.filter(&(Enum.at(&1, 0) == "acheteur"))
    sellers = socket.assigns.actors |> Enum.filter(&(Enum.at(&1, 0) == "vendeur"))
    market = Market.new(buyers, sellers)

    {:noreply,
     assign(socket, :step, :sim)
     |> assign(:market, market)
     |> assign(:period_index, 0)}
  end

  def handle_event("back-to-preparation", _, socket) do
    {:noreply, assign(socket, :step, :preparation)}
  end

  def handle_event("finish-sim", _, socket) do
    graph =
      Market.results(socket.assigns.market)
      |> Enum.map(fn %{x: x, y: y} -> [x, y] end)
      |> IO.inspect()
      |> make_graph("Evolution du prix par transaction")

    {:noreply, assign(socket, :step, :result) |> assign(:graph, graph)}
  end

  def handle_event("restart-sim", _, socket) do
    market = Market.new(socket.assigns.market)
    {:noreply, assign(socket, :market, market) |> assign(:period_index, 0)}
  end

  def handle_event(
        "add-action",
        %{"actor" => actor, "price" => price},
        %{assigns: %{market: market}} = socket
      ) do
    price =
      case Integer.parse(price) do
        :error -> 0
        {number, _} -> number
      end

    case Market.actor(market, actor) do
      nil ->
        {:noreply, put_flash(socket, :error, "L'acteur donné n'existe pas.")}

      actor ->
        case Market.update(market, :offer, %{actor: actor, price: price}) do
          {:ok, market} ->
            {:noreply, socket |> assign(:market, market)}

          {:error, :price_not_in_wt} ->
            {:noreply,
             put_flash(
               socket,
               :error,
               "Le prix donné ne respecte pas le prix de consentement de l'acteur."
             )}
        end
    end
  end

  def handle_event(
        "accept-price",
        %{"actors-input-vendeur" => actor},
        socket
      ) do
    market = socket.assigns.market
    actor = Market.actor(market, actor)

    case Market.update(market, :accept, %{actor: actor}) do
      {:ok, market} ->
        {:noreply, socket |> assign(:market, market)}

      {:error, error} ->
        IO.inspect(error)
        {:noreply, socket |> put_flash(:error, "Erreur")}
    end
  end

  def handle_event(
        "accept-price",
        %{"actors-input-buyer" => actor},
        socket
      ) do
    market = socket.assigns.market
    actor = Market.actor(market, actor)

    case Market.update(market, :accept, %{actor: actor}) do
      {:ok, market} ->
        {:noreply, socket |> assign(:market, market)}

      {:error, error} ->
        IO.inspect(error)
        {:noreply, socket |> put_flash(:error, "Erreur")}
    end
  end

  def handle_event("undo-last-action", %{}, socket) do
    {:noreply, assign(socket, :market, Market.undo(socket.assigns.market))}
  end

  def handle_event("add-period", %{}, socket) do
    {:ok, market} = Market.update(socket.assigns.market, :add_period)
    {:noreply, assign(socket, :market, market)}
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

    periods = [
      # Period 1: David accepts Bruno at 20, Alice accepts Émilie at 17
      [
        {:offer, "Alice", 22},
        {:offer, "David", 14},
        {:offer, "Bruno", 20},
        {:accept, "David"},
        {:offer, "Émilie", 15},
        {:offer, "Alice", 19},
        {:offer, "Émilie", 17},
        {:accept, "Alice"},
        {:offer, "Chloé", 24},
        {:offer, "François", 8},
        {:offer, "Chloé", 22},
        {:offer, "François", 10}
      ],
      # Period 2: David accepts Alice at 17, Émilie accepts Bruno at 17
      [
        {:offer, "Bruno", 19},
        {:offer, "Émilie", 14},
        {:offer, "Alice", 18},
        {:offer, "David", 16},
        {:offer, "Alice", 17},
        {:accept, "David"},
        {:offer, "Émilie", 15},
        {:offer, "Bruno", 17},
        {:accept, "Émilie"},
        {:offer, "Chloé", 22},
        {:offer, "François", 10}
      ],
      # Period 3: Bruno accepts Émilie at 16, Alice accepts David at 16
      [
        {:offer, "David", 15},
        {:offer, "Bruno", 18},
        {:offer, "Émilie", 16},
        {:accept, "Bruno"},
        {:offer, "Alice", 17},
        {:offer, "David", 16},
        {:accept, "Alice"},
        {:offer, "Chloé", 21},
        {:offer, "François", 9}
      ],
      # Period 4: Émilie accepts Bruno at 16, Alice accepts David at 16
      [
        {:offer, "Alice", 17},
        {:offer, "Émilie", 16},
        {:offer, "Bruno", 16},
        {:accept, "Émilie"},
        {:offer, "David", 16},
        {:accept, "Alice"},
        {:offer, "Chloé", 20},
        {:offer, "François", 10}
      ]
    ]

    periods
    |> Enum.with_index()
    |> Enum.reduce(Market.new(buyers, sellers), fn {actions, index}, market ->
      market =
        if index == 0 do
          market
        else
          {:ok, market} = Market.update(market, :add_period)
          market
        end

      Enum.reduce(actions, market, &apply_test_action/2)
    end)
  end

  defp apply_test_action({:offer, name, price}, market) do
    {:ok, market} =
      Market.update(market, :offer, %{actor: Market.actor(market, name), price: price})

    market
  end

  defp apply_test_action({:accept, name}, market) do
    {:ok, market} = Market.update(market, :accept, %{actor: Market.actor(market, name)})
    market
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
end
