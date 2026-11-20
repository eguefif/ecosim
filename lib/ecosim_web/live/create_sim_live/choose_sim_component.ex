defmodule EcosimWeb.CreateSimLive.ChooseSimComponent do
  @moduledoc """
  Step 1 of the simulation creation: choose which simulation to run.
  """

  use EcosimWeb, :html

  import EcosimWeb.CreateSimLive.Transitions, only: [go: 2]

  attr :sim, :string, default: nil, doc: "the currently selected simulation type"

  def choose_sim(assigns) do
    ~H"""
    <div class="flex flex-row gap-[16px]">
      <div class={[@sim == "market" && "aura"]}>
        <div
          class={[
            "card bg-base-100 w-[256px] shadow-md hover:scale-102 hover:pointer transition-transform duration-200 ease-in-out"
          ]}
          phx-click={go("choose-sim", %{sim: "market"})}
        >
          <figure>
            <img src={~p"/images/market-card.jpg"} alt={gettext("Market")} />
          </figure>
          <div class="card-body">
            <h2 class="card-title">
              {gettext("The Market")}
            </h2>
            <p>{gettext("Simulate a market following Vernon Smith's 1962 protocol.")}</p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
