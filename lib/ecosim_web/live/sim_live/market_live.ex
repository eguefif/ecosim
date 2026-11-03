defmodule EcosimWeb.Sim.MarketLive do
  use EcosimWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Market - ({get_mode(@mode)})
    </.header>
    """
  end

  defp get_mode("one-for-all"), do: "Un utilisateur pour tous"
  defp get_mode("bot"), do: "Utilisateur avec bot"
  defp get_mode("multi"), do: "Multi utilisateur"

  @impl true
  def mount(%{"mode" => mode}, _session, socket) do
    {:ok, socket |> assign(:mode, mode)}
  end
end
