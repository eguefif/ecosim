defmodule EcosimWeb.Sim.MarketLive do
  use EcosimWeb, :live_view

  alias EcosimWeb.SimLive.OneForAllModeLive, as: OneMode
  alias Ecosim.Sim.Market
  alias Ecosim.Sim.Market.Actor

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Market - ({get_mode(@mode)})
      <:subtitle :if={@step == :preparation}>1 - Préparation</:subtitle>
      <:subtitle :if={@step == :sim}>2 - Simulation</:subtitle>
      <:subtitle :if={@step == :result}>3 - Result</:subtitle>
    </.header>

    <OneMode.preparation
      :if={@step == :preparation}
      mode={@mode}
      uploads={@uploads}
      participants={@participants}
    />

    <OneMode.sim :if={@step == :sim} market={@market} period_index={@period_index} />

    <OneMode.result :if={@step == :result} />
    """
  end

  defp get_mode("one-for-all"), do: "Un utilisateur pour tous"
  defp get_mode("bot"), do: "Utilisateur avec bot"
  defp get_mode("multi"), do: "Multi utilisateur"

  @impl true
  def mount(%{"mode" => mode}, _session, socket) do
    # TODO: remove hardcoded test data, restore `:preparation` step and empty participants
    participants = [
      ["vendeur", "Alice", "12"],
      ["vendeur", "Bruno", "15"],
      ["vendeur", "Chloé", "20"],
      ["acheteur", "David", "25"],
      ["acheteur", "Émilie", "18"],
      ["acheteur", "François", "10"]
    ]

    [david, emilie, francois] =
      buyers = [
        Actor.new(:buyer, "David", 25),
        Actor.new(:buyer, "Émilie", 18),
        Actor.new(:buyer, "François", 10)
      ]

    [alice, bruno, chloe] =
      sellers = [
        Actor.new(:seller, "Alice", 12),
        Actor.new(:seller, "Bruno", 15),
        Actor.new(:seller, "Chloé", 20)
      ]

    market = Market.new(buyers, sellers)
    {:ok, market} = Market.update(market, :sell_at, %{actor: alice, price: 22})
    {:ok, market} = Market.update(market, :buy_at, %{actor: david, price: 14})
    {:ok, market} = Market.update(market, :sell_at, %{actor: bruno, price: 20})
    # David accepts Bruno's offer: transaction at 20
    {:ok, market} = Market.update(market, :accept, %{actor: david})
    {:ok, market} = Market.update(market, :buy_at, %{actor: emilie, price: 16})
    {:ok, market} = Market.update(market, :sell_at, %{actor: alice, price: 19})
    {:ok, market} = Market.update(market, :buy_at, %{actor: emilie, price: 17})
    # Alice accepts Émilie's offer: transaction at 17
    {:ok, market} = Market.update(market, :accept, %{actor: alice})
    {:ok, market} = Market.update(market, :sell_at, %{actor: chloe, price: 24})
    {:ok, market} = Market.update(market, :buy_at, %{actor: francois, price: 8})

    {:ok,
     socket
     |> assign(:mode, mode)
     |> assign(:step, :sim)
     |> assign(:market, market)
     |> assign(:period_index, 0)
     |> assign(:participants, participants)
     |> allow_upload(:participants,
       accept: ~w(.txt .csv),
       max_entries: 1,
       max_file_size: 1_000_000
     )}
  end

  @impl true
  def handle_event("start", _, socket) do
    buyers = socket.assigns.participants |> Enum.filter(&(Enum.at(&1, 0) == "acheteur"))
    sellers = socket.assigns.participants |> Enum.filter(&(Enum.at(&1, 0) == "vendeur"))
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
    {:noreply, assign(socket, :step, :result)}
  end

  def handle_event("restart-sim", _, socket) do
    market = Market.new(socket.assigns.market)
    {:noreply, assign(socket, :market, market) |> assign(:period_index, 0)}
  end

  def handle_event("show-day", %{"period" => period}, socket) do
    {:noreply, assign(socket, :period_index, period)}
  end

  def handle_event("validate_upload", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :participants, ref)}
  end

  def handle_event("save_upload", _params, socket) do
    content =
      socket
      |> consume_uploaded_entries(:participants, fn %{path: path}, _entry ->
        {:ok, File.read!(path)}
      end)
      |> List.first()

    participants = parse_content(content)

    {:noreply, assign(socket, :participants, participants)}
  end

  defp parse_content(content) do
    content
    |> String.split("\n", trim: true)
    |> Enum.map(&(String.split(&1, ",") |> Enum.map(fn entry -> String.trim(entry) end)))
  end
end
