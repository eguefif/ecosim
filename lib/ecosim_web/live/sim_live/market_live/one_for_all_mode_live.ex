defmodule EcosimWeb.SimLive.MarketLive.OneForAllModeLive do
  use EcosimWeb, :live_view

  def preparation_one_for_all_mode(assigns) do
    ~H"""
    <div class="flex flex-col gap-[16px]">
      <.show_instructions />
    </div>
    """
  end

  def show_instructions(assigns) do
    ~H"""
    <div>
      {gettext("This mode requires some preparation:")}<br />
      <ul>
        <li>
          1. {gettext(
            "Choose a supply and demand graph to define the willingness to accept and to pay (WTA and WTP)."
          )}
        </li>
        <li>
          2. {gettext("Generate the distribution of sellers and buyers with their WTA and WTP.")}
        </li>
        <li>3. {gettext("Give each participant their role and their WTA or WTP.")}</li>
      </ul>
    </div>
    """
  end
end
