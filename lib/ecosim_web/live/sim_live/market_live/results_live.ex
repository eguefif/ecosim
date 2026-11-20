defmodule EcosimWeb.SimLive.MarketLive.ResultsLive do
  use EcosimWeb, :live_view

  alias EcosimWeb.ChartsLive.LineChartLive

  attr :info, :map, default: nil

  def result(assigns) do
    ~H"""
    <div class="flex flex-col gap-[32px]">
      <div class="text-lg font-bold">{gettext("Results")}</div>
      <div class="flex flex-row gap[-32px] justify-around">
        <LineChartLive.plot_line
          title={gettext("Market Graph")}
          labels={[gettext("buyer"), gettext("seller")]}
          values={@info.market_plot}
        />

        <LineChartLive.plot_line
          title={gettext("Experience result 1")}
          labels={[gettext("Transactions")]}
          values={[@info.price_per_transaction_plot]}
        />

        <LineChartLive.plot_line
          title="Experience result 2"
          labels={[gettext("Transactions per period")]}
          values={[@info.transactions_per_period_plot]}
        />
      </div>
    </div>
    """
  end
end
