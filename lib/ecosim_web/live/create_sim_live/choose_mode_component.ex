defmodule EcosimWeb.CreateSimLive.ChooseModeComponent do
  @moduledoc """
  Step 2 of the simulation creation: choose how the simulation is played
  (one user for all, multi-user, or one user with bots).
  """

  use EcosimWeb, :html

  import EcosimWeb.CreateSimLive.Transitions, only: [go: 2]

  attr :mode, :string, default: nil, doc: "the currently selected mode"

  def choose_mode(assigns) do
    ~H"""
    <div class="flex flex-row gap-[32px] transform-transition">
      <div class={[@mode == "one-for-all" && "aura"]}>
        <div
          class={[
            "card bg-base-100 w-[256px] h-[192px] shadow-md hover:scale-104 duration-200 transition-transform ease-in-out hover:pointer"
          ]}
          phx-click={go("choose-mode", %{mode: "one-for-all"})}
        >
          <div class="card-body">
            <h2 class="card-title">
              {gettext("One user for all")}
            </h2>
            <p>
              {gettext(
                "In this mode, one user provides the list of economic actors and records every action."
              )}
            </p>
          </div>
        </div>
      </div>

      <div class={[@mode == "multi" && "aura"]}>
        <div
          class="card bg-base-100 w-[256px] h-[192px] shadow-md hover:scale-104 duration-200 transition-transform ease-in-out hover:pointer"
          phx-click={go("choose-mode", %{mode: "multi"})}
        >
          <div class="card-body">
            <h2 class="card-title">
              {gettext("Multi-user")}
            </h2>
            <p>
              {gettext(
                "In this mode, each user uses their own device and joins the simulation with a code."
              )}
            </p>
          </div>
        </div>
      </div>

      <div class={[@mode == "bot" && "aura"]}>
        <div
          class="card bg-base-100 w-[256px] h-[192px] shadow-md hover:scale-104 duration-200 transition-transform ease-in-out hover:pointer"
          phx-click={go("choose-mode", %{mode: "bot"})}
        >
          <div class="card-body">
            <h2 class="card-title">
              {gettext("One user with bots")}
            </h2>
            <p>
              {gettext("In this mode, one user runs the simulation with bots.")}
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
