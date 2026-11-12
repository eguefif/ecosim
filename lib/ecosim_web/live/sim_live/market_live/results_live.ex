defmodule EcosimWeb.SimLive.MarketLive.ResultsLive do
  use EcosimWeb, :live_view

  attr :result_graph, :any
  attr :market_graph, :any

  def result(assigns) do
    ~H"""
    <div class="flex flex-col gap-[32px]">
      <div class="text-lg font-bold">{gettext("3 - Results")}</div>
      <div class="flex flex-row gap[-32px] justify-around">
        {@result_graph}
      </div>
    </div>
    """
  end
end
