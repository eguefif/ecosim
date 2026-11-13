defmodule EcosimWeb.SimLive.MarketLive.MultiModeLive do
  use EcosimWeb, :live_view

  attr :join_code, :integer, required: true

  def preparation_multi(assigns) do
    ~H"""
    <div class="card bg-base-100 w-[384px] shadow-md mx-auto">
      <div class="card-body mx-auto gap-[32px]">
        <div class="card-title mx-auto">
          {gettext("Code")}
        </div>
        <div class="text-8xl">
          {@join_code}
        </div>
      </div>
    </div>
    """
  end
end
