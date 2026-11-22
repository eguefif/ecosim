defmodule EcosimWeb.SimLive.MarketLive.PreparationLive do
  use EcosimWeb, :live_view

  alias Ecosim.SimServer

  attr :sim_id, :integer

  def preparation(assigns) do
    ~H"""
    <div class="flex flex-col gap-[32px]">
      <.show_preparation_action_buttons sim_id={@sim_id} />

      <.show_market_model_choices market_choice={market_choice(@sim_id)} />
    </div>
    """
  end

  attr :sim_id, :integer

  def show_preparation_action_buttons(assigns) do
    ~H"""
    <div class="flex flex-row gap-[8px] justify-around shadow-md p-[16px] rounded-lg">
      <button
        class={["btn btn-primary w-[96px] mx-auto"]}
        phx-click="start"
      >
        {gettext("Start")}
      </button>
      <button
        type="button"
        name="click-generate-file"
        phx-click="user-click-generate-file"
        class="btn btn-secondary"
      >
        {gettext("Generate file")}
      </button>
      <a
        id="download-actors"
        href={"data:text/csv;base64," <> Base.encode64(sim_participants(@sim_id))}
        download="actors.csv"
        class="btn btn-secondary"
      >
        {gettext("Generate Actors File")}
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

  defp sim_participants(sim_id), do: SimServer.sim_participants(sim_id) |> Enum.join(", ")

  defp market_choice(sim_id), do: SimServer.info(sim_id) |> Map.get(:market_model)
end
