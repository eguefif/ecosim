defmodule EcosimWeb.SimLive.Market.CommonLive do
  use EcosimWeb, :live_view

  alias EcosimWeb.SimLive.OneForAllModeLive, as: OneMode

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

  def(show_sim_action_buttons(assigns)) do
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

  def show_events(assigns) do
    ~H"""
    <div class="flex flex-row gap-[64px] justify-between w-[640]">
      <.show_transactions info={@info} />
      <div class="divider divider-horizontal"></div>
      <.show_all_actions info={@info} />
    </div>
    """
  end

  attr :info, :map

  def show_transactions(assigns) do
    ~H"""
    <.show_actions
      actions={@info.transactions |> Enum.reverse()}
      label={gettext("Transactions")}
      row_item={
        fn action ->
          actors = Map.get(action.params, :actors)
          price = Map.get(action.params, :price)
          [Enum.at(actors, 0), Enum.at(actors, 1), price]
        end
      }
    >
      <:action_row :let={[actor1, actor2, price]}>
        <div class="shadow-md p-[16px] rounded-lg text-center bg-transaction" ,>
          {transaction_text(actor1, actor2, price)}
        </div>
      </:action_row>
    </.show_actions>
    """
  end

  attr :info, :map

  def show_all_actions(assigns) do
    ~H"""
    <.show_actions
      actions={@info.events |> Enum.reverse()}
      label={gettext("Events")}
      row_item={
        fn action ->
          if action.action == :transact do
            actor1 = Map.get(action.params, :actors) |> Enum.at(0)
            actor2 = Map.get(action.params, :actors) |> Enum.at(1)
            price = Map.get(action.params, :price)
            [{actor1.name, actor2.name}, :transact, price]
          else
            actor = Map.get(action.params, :actor)
            price = Map.get(action.params, :price)
            [actor, action.action, price]
          end
        end
      }
    >
      <:action_row :let={[actor, action_type, price]}>
        <div
          :if={action_type == :transact}
          class={[
            "shadow-md p-[16px] rounded-lg text-center",
            "bg-transaction"
          ]}
        >
          {transaction_between_text(actor, price)}
        </div>
        <div
          :if={action_type != :transact}
          class={[
            "shadow-md p-[16px] rounded-lg text-center",
            action_type == :sell_at && "bg-seller",
            action_type == :buy_at && "bg-buyer"
          ]}
        >
          {action_text(action_type, actor.name, price)}
        </div>
      </:action_row>
    </.show_actions>
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
