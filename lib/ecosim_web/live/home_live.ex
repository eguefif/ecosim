defmodule EcosimWeb.HomeLive do
  use EcosimWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-screen flex flex-col">
      <div class="flex flex-row gap-[32px] w-[196px] h-[196px] mx-auto my-auto">
        <a
          href={~p"/create-sim"}
          class="container shadow-md p-[64px] scale-100 hover:scale-110 duration-200 transform-transition ease-in-out rounded-md bg-base-200"
        >
          {gettext("New simulation")}
        </a>
        <a
          href={~p"/join-sim"}
          class="container shadow-md p-[64px] scale-100 hover:scale-110 duration-200 transform-transition ease-in-out rounded-md bg-base-200"
        >
          {gettext("Join simulation")}
        </a>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_parms, _session, socket) do
    {:ok, socket}
  end
end
