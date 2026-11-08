defmodule EcosimWeb.HomeLive do
  use EcosimWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-screen">
      <div class="flex flex-col md:flex-row gap-[32px] justify-center">
        <a
          href={~p"/create-sim"}
          class="container shadow-md p-[64px] w-[256] scale-100 hover:scale-110 duration-200 transform-transition ease-in-out rounded-md bg-base-200 text-center"
        >
          {gettext("Create a simulation")}
        </a>
        <a
          href={~p"/join-sim"}
          class="container shadow-md p-[64px] w-[256] scale-100 hover:scale-110 duration-200 transform-transition ease-in-out rounded-md bg-base-200 text-center"
        >
          {gettext("Join a simulation")}
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
