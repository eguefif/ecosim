defmodule EcosimWeb.SimLive.Market.CommonLive do
  use EcosimWeb, :live_view

  alias EcosimWeb.SimLive.OneForAllModeLive, as: OneMode

  attr :mode, :string
  attr :uploads, :map, required: true
  attr :actors, :list

  def preparation(assigns) do
    ~H"""
    <div class="flex flex-col gap-[8px]">
      <OneMode.preparation_one_for_all_mode :if={@mode == "one-for-all"} uploads={@uploads} />

      <.show_actors :if={@actors != []} actors={@actors} />
      <div class="divider"></div>
      <div
        class={["btn btn-primary w-[96px] mx-auto", @actors == [] && "btn-disabled"]}
        phx-click="start"
      >
        Démarrer
      </div>
    </div>
    """
  end

  attr :actors, :list, required: true

  def show_actors(assigns) do
    ~H"""
    <div class="divider text-xl">actors</div>
    <ul id="actors" class="list gap-[4px]">
      <li
        :for={[type, name, _] <- @actors}
        class={[
          type == "acheteur" && "bg-buyer",
          type == "vendeur" && "bg-seller",
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

  defp get_type("vendeur"), do: "Vendeur"
  defp get_type("acheteur"), do: "Acheteur"

  attr :graph, :any

  def result(assigns) do
    ~H"""
    <div>Result</div>
    {@graph}
    """
  end
end
