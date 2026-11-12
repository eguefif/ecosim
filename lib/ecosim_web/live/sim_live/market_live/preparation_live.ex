defmodule EcosimWeb.SimLive.MarketLive.PreparationLive do
  use EcosimWeb, :live_view
  alias EcosimWeb.SimLive.MarketLive.OneForAllModeLive, as: OneMode

  attr :mode, :string
  attr :uploads, :map, required: true
  attr :actors, :list
  attr :market_model, :integer, default: -1
  attr :actors_file, :string, default: nil
  attr :market, Market

  def preparation(assigns) do
    ~H"""
    <div class="flex flex-col gap-[32px]">
      <.show_preparation_action_buttons actors={@actors} actors_file={@actors_file} />

      <.show_market_model_choices market_choice={@market_model} />

      <OneMode.preparation_one_for_all_mode
        :if={@mode == "one-for-all"}
        uploads={@uploads}
      />

      <.show_actors :if={@actors != []} actors={@actors} />
    </div>
    """
  end

  attr :actors, :list
  attr :actors_file, :string

  def show_preparation_action_buttons(assigns) do
    ~H"""
    <div class="flex flex-row gap-[8px] justify-around shadow-md p-[16px] rounded-lg">
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
      <div :if={@actors != []}>
        <button
          type="button"
          name="click-generate-file"
          phx-click="user-click-generate-file"
          class="btn btn-secondary"
        >
          {gettext("Generate file")}
        </button>
      </div>
      <a
        :if={@actors_file != nil}
        id="download-actors"
        href={"data:text/csv;base64," <> Base.encode64(@actors_file)}
        download="actors.csv"
        class="btn btn-secondary"
      >
        {gettext("Download File")}
      </a>
    </div>
    """
  end

  attr :market_choice, :integer, default: 1

  def show_market_model_choices(assigns) do
    ~H"""
    <div class="flex flex-col gap-[32px]">
      <div class="text-lg font-bold">{gettext("Choose a Market Model")}</div>
      <div class="flex flex-row gap-[32px]">
        <div class={[
          @market_choice == 1 && "aura",
          @market_choice != 1 && "hover:scale-104 duration-200 transform-transition ease-in-out"
        ]}>
          <div
            class="card shadow-md rounded-lg p-1 w-[194px]"
            phx-click="select-model"
            phx-value-model="1"
          >
            <figure class="rounded-xl">
              <img src={~p"/images/market1.png"} alt="market" class="object-cover" />
            </figure>
          </div>
        </div>

        <div class={[
          @market_choice == 2 && "aura",
          @market_choice != 2 && "hover:scale-104 duration-200 transform-transition ease-in-out"
        ]}>
          <div
            class="card shadow-md rounded-lg p-1 w-[194px]"
            phx-click="select-model"
            phx-value-model="2"
          >
            <figure class="rounded-xl">
              <img src={~p"/images/market2.png"} alt="market" class="object-cover" />
            </figure>
          </div>
        </div>

        <div class={[
          @market_choice == 3 && "aura",
          @market_choice != 3 && "hover:scale-104 duration-200 transform-transition ease-in-out"
        ]}>
          <div
            class="card shadow-md rounded-lg p-1 w-[194px]"
            phx-click="select-model"
            phx-value-model="3"
          >
            <figure class="rounded-xl">
              <img src={~p"/images/market3.png"} alt="market" class="object-cover" />
            </figure>
          </div>
        </div>
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
end
