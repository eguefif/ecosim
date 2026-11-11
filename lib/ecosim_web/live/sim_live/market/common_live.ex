defmodule EcosimWeb.SimLive.Market.CommonLive do
  use EcosimWeb, :live_view

  alias EcosimWeb.SimLive.OneForAllModeLive, as: OneMode
  alias Ecosim.Sim.Market
  alias Ecosim.Sim.Market.Period
  alias Ecosim.Sim.Market.Action

  attr :mode, :string
  attr :uploads, :map, required: true
  attr :actors, :list
  attr :market_model, :integer, default: -1

  def preparation(assigns) do
    ~H"""
    <div class="flex flex-col gap-[8px]">
      <OneMode.preparation_one_for_all_mode
        :if={@mode == "one-for-all"}
        uploads={@uploads}
        market_model={@market_model}
      />

      <.show_actors :if={@actors != []} actors={@actors} />
      <div class="flex flex-row gap-[8px] justify-around">
        <div class="divider"></div>
        <button
          class={["btn btn-primary w-[96px] mx-auto", @actors == [] && "btn-disabled"]}
          phx-click="start"
        >
          {gettext("Start")}
        </button>
        <button
          type="submit"
          id="default-list-button"
          phx-click="user-click-default-button"
          class="btn btn-secondary"
        >
          {gettext("Use example list")}
        </button>
      </div>
    </div>
    """
  end

  attr :actors, :list, required: true

  def show_actors(assigns) do
    ~H"""
    <div class="divider text-xl">{gettext("Actors")}</div>
    <ul id="actors" class="list gap-[4px]">
      <li
        :for={name <- @actors}
        class="list-row items-baseline flex flex-row justify-between bg-info"
      >
        <div class="flex flex-row gap-[16px] items-baseline">
          <span class="text-lg font-bold">{name}</span>
        </div>
        <button class="btn btn-square btn-ghost">
          <.icon name="hero-x-mark" />
        </button>
      </li>
    </ul>
    """
  end

  attr :result_graph, :any
  attr :market_graph, :any

  def result(assigns) do
    ~H"""
    <div class="flex flex-col gap-[32px]">
      <div class="text-lg font-bold">{gettext("3 - Results")}</div>
      <div class="flex flex-row gap[-32px] justify-around">
        {@result_graph}
      </div>
    </div>
    """
  end

  slot :inner_block

  attr :market, Market
  attr :period_index, :integer, default: 0
  attr :offer_focus_actor_name, :string

  def sim(assigns) do
    ~H"""
    <div class="flex flex-col gap-[32px]">
      <.show_sim_action_buttons>
        <.show_add_action_form actors={Market.active_actors(@market, @period_index)} />
      </.show_sim_action_buttons>
      <.show_periods periods={length(@market.periods)} current_period={@period_index} />
      <.show_current_period
        info={Enum.at(@market.periods, @period_index) |> Period.info()}
        actors={Market.active_actors(@market, @period_index)}
        offer_focus_actor_name={@offer_focus_actor_name}
      />
    </div>
    """
  end

  attr :actors, :list

  def show_add_action_form(assigns) do
    ~H"""
    <div class="p-[16px] flex justify-center">
      <form id="one-for-all-add-action-form" phx-submit="add-action">
        <div class="flex flex-row gap-[8px]">
          <.live_component
            module={EcosimWeb.SimLive.Market.InputAutocompleteComponent}
            id="actor-input"
            actors={@actors}
          />
          <input
            id="price"
            name="price"
            type="text"
            class="input w-[64px]"
            placeholder={gettext("price")}
          />
          <button type="submit" class="btn btn-primary">{gettext("Add")}</button>
        </div>
      </form>
    </div>
    """
  end

  def show_sim_action_buttons(assigns) do
    ~H"""
    <div class="flex flex-col gap-[8px] shadow-md p-[32px]">
      <div class="flex flex-row justify-around">
        <div class="btn btn-warning gap-2" phx-click="restart-sim">
          <.icon name="hero-arrow-path" class="size-5" />
          {gettext("Reset")}
        </div>
        <div class="btn btn-primary gap-2" phx-click="finish-sim">
          <.icon name="hero-flag" class="size-5" />
          {gettext("Finish")}
        </div>
        <div class="btn btn-warning gap-2" phx-click="undo-last-action">
          <.icon name="hero-arrow-uturn-left" class="size-5" />
          {gettext("Undo")}
        </div>
      </div>
      <div class="divider"></div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :periods, :integer
  attr :current_period, :integer

  def show_periods(assigns) do
    ~H"""
    <div class="flex flex-row gap-[8px]">
      <.button phx-click="add-period"><.icon name="hero-plus" class="size-5" /></.button>
      <div
        :for={n <- 0..(@periods - 1)}
        class="btn btn-info"
        disabled={@current_period == n}
        phx-click="show-period"
        phx-value-period={n}
      >
        {gettext("Period %{number}", number: n + 1)}
      </div>
    </div>
    """
  end

  attr :info, :map
  attr :actors, :list
  attr :offer_focus_actor_name, :string, default: nil

  def show_current_period(assigns) do
    ~H"""
    <div class="flex flex-row gap-[32px]">
      <.show_buyers_prices
        offers={@info.buyers_prices}
        offer_focus_actor_name={@offer_focus_actor_name}
        actors={Enum.filter(@actors, &(&1.type == :seller)) |> Enum.map(& &1.name)}
      />
      <div class="divider divider-horizontal"></div>
      <.show_transactions transactions={@info.transactions} />
      <div class="divider divider-horizontal"></div>
      <.show_sellers_prices
        offers={@info.sellers_prices}
        offer_focus_actor_name={@offer_focus_actor_name}
        actors={Enum.filter(@actors, &(&1.type == :buyer)) |> Enum.map(& &1.name)}
      />
    </div>
    """
  end

  attr :offers, :list
  attr :actors, :list
  attr :offer_focus_actor_name, :string

  def show_buyers_prices(assigns) do
    ~H"""
    <div class="flex flex-col w-full items-center">
      <div class="text-lg font-bold">{gettext("Buyer's offers")}</div>
      <div class="divider"></div>
      <div class="flex flex-col gap-[8px]">
        <div
          :for={offer <- @offers}
          class="bg-buyer shadow-md p-[16px] rounded-lg hover:scale-104 duration-200 transform-transition ease-in-out pointer"
          phx-click="user-click-offer"
          phx-click-away="user-click-away-from-offer"
          phx-value-offer={offer.params.actor.name}
        >
          {action_text(:buy_at, offer.params.actor.name, offer.params.price)}
          <div :if={@offer_focus_actor_name == offer.params.actor.name}>
            <.show_select_transaction_form actors={@actors} type="seller" price={offer.params.price} />
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :offers, :list
  attr :actors, :list
  attr :offer_focus_actor_name, :string

  def show_sellers_prices(assigns) do
    ~H"""
    <div class="flex flex-col w-full items-center">
      <div class="text-lg font-bold">{gettext("Seller's offers")}</div>
      <div class="divider"></div>
      <div class="flex flex-col gap-[8px]">
        <div
          :for={offer <- @offers}
          class="bg-seller shadow-md p-[16px] rounded-lg  hover:scale-104 duration-200 transform-transition ease-in-out pointer"
          phx-click="user-click-offer"
          phx-click-away="user-click-away-from-offer"
          phx-value-offer={offer.params.actor.name}
        >
          {action_text(:sell_at, offer.params.actor.name, offer.params.price)}
          <div :if={@offer_focus_actor_name == offer.params.actor.name}>
            <.show_select_transaction_form
              actors={@actors}
              type="buyer"
              price={offer.params.price}
            />
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :actors, :list
  attr :type, :string
  attr :price, :any

  def show_select_transaction_form(assigns) do
    ~H"""
    <form id={"select-transaction-form-#{@type}"} phx-change="accept-price">
      <.input type="hidden" name="price" value={@price} />
      <.input
        type="select"
        name={"actors-input-#{@type}"}
        value=""
        prompt={gettext("Choose")}
        options={@actors}
      />
    </form>
    """
  end

  attr :transactions, :map

  def show_transactions(assigns) do
    ~H"""
    <div class="flex flex-col w-full items-center">
      <div class="text-lg font-bold">{gettext("Transactions")}</div>
      <div class="divider"></div>
      <div class="flex flex-col gap-[8px]">
        <div
          :for={
            %Action{action: :transact, params: %{actors: [actor1, actor2], price: price}} <-
              @transactions
          }
          class="bg-transaction shadow-md p-[16px] rounded-lg"
        >
          {transaction_text(actor1, actor2, price)}
        </div>
      </div>
    </div>
    """
  end

  attr :label, :string
  attr :actions, :list
  slot :action_row

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row"

  def show_actions(assigns) do
    ~H"""
    <div class="flex flex-col w-full items-center">
      <div class="text-lg font-bold">{@label}</div>
      <div class="divider"></div>
      <div class="flex flex-col gap-[8px]">
        <div :for={action <- @actions}>
          {render_slot(@action_row, @row_item.(action))}
        </div>
      </div>
    </div>
    """
  end

  # Sentences are translated as a whole (word order differs between languages).
  # Interpolated values are HTML-escaped and rendered in bold; the translated
  # templates themselves come from our own .po files.
  defp transaction_text(actor1, actor2, price) do
    {seller, buyer} =
      if actor1.type == :seller do
        {actor1.name, actor2.name}
      else
        {actor2.name, actor1.name}
      end

    gettext("%{seller} sells to %{buyer} at the price of %{price}",
      seller: bold(seller),
      buyer: bold(buyer),
      price: bold(price)
    )
    |> raw()
  end

  defp transaction_between_text({actor1, actor2}, price) do
    gettext("Transaction between %{actor1} and %{actor2} at %{price}",
      actor1: bold(actor1),
      actor2: bold(actor2),
      price: bold(price)
    )
    |> raw()
  end

  defp action_text(:sell_at, actor, price) do
    gettext("%{actor} sells at %{price}", actor: bold(actor), price: bold(price)) |> raw()
  end

  defp action_text(:buy_at, actor, price) do
    gettext("%{actor} buys at %{price}", actor: bold(actor), price: bold(price)) |> raw()
  end

  defp bold(value) do
    escaped = value |> to_string() |> html_escape() |> safe_to_string()
    ~s(<span class="font-bold">#{escaped}</span>)
  end
end
