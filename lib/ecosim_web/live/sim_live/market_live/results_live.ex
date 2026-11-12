defmodule EcosimWeb.SimLive.MarketLive.ResultsLive do
  use EcosimWeb, :live_view

  alias EcosimWeb.ChartsLive.LineChartLive
  alias Ecosim.Sim.Market

  attr :market, :any, default: nil

  def result(assigns) do
    ~H"""
    <div class="flex flex-col gap-[32px]">
      <div class="text-lg font-bold">{gettext("Results")}</div>
      <div class="flex flex-row gap[-32px] justify-around">
        <LineChartLive.plot_line
          title={gettext("Market Graph")}
          labels={[gettext("buyer"), gettext("seller")]}
          values={market_plot(@market)}
        />

        <LineChartLive.plot_line
          title={gettext("Experience result 1")}
          labels={[gettext("Transactions")]}
          values={[result_plot(@market)]}
        />

        <LineChartLive.plot_line
          title="Experience result 2"
          labels={[gettext("Transactions per period")]}
          values={[transaction_per_period_plot(@market)]}
        />
      </div>
    </div>
    """
  end

  defp market_plot(%Market{} = market), do: Market.market_plot_data(market)
  defp result_plot(%Market{} = market), do: Market.result_plot_data(market)

  defp transaction_per_period_plot(%Market{} = market),
    do: Market.transaction_per_period_plot_data(market)
end
