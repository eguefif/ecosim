defmodule EcosimWeb.SimLive.Market.CommonLive do
  use EcosimWeb, :live_view

  alias EcosimWeb.SimLive.OneForAllModeLive, as: OneMode
  alias Ecosim.Sim.Market.Actor

  attr :mode, :string
  attr :uploads, :map, required: true
  attr :actors, :list

  def preparation(assigns) do
    ~H"""
    <div class="flex flex-col gap-[8px]">
      <OneMode.preparation_one_for_all_mode :if={@mode == "one-for-all"} uploads={@uploads} />

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
        :for={[type, name, _] <- @actors}
        class={[
          Actor.type_string_to_atom(type) == :buyer && "bg-buyer",
          Actor.type_string_to_atom(type) == :seller && "bg-seller",
          "list-row items-baseline flex flex-row justify-between"
        ]}
      >
        <div class="flex flex-row gap-[16px] items-baseline">
          <span class="text-lg font-bold">{name}</span><span class="italic">{get_type(type)}</span>
        </div>
        <button class="btn btn-square btn-ghost">
          <.icon name="hero-x-mark" />
        </button>
      </li>
    </ul>
    """
  end

  defp get_type(type) do
    case Actor.type_string_to_atom(type) do
      :seller -> gettext("Seller")
      :buyer -> gettext("Buyer")
      nil -> type
    end
  end

  attr :graph, :any

  def result(assigns) do
    ~H"""
    <div>{gettext("Results")}</div>
    {@graph}
    """
  end
end
