defmodule EcosimWeb.HomeLive do
  use EcosimWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>Hello, World</div>
    """
  end

  @impl true
  def mount(_parms, _session, socket) do
    {:ok, socket}
  end
end
