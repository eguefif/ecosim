defmodule Ecosim.MarketTest do
  use Ecosim.DataCase

  alias Ecosim.Market

  setup do
    buyers = ["b1", "b3"]
    sellers = ["s1", "s2"]
    market = Market.create(buyers, sellers)
    [market: market]
  end

  describe "Market" do
    test "add a new period on update :add_period", %{market: market} do
      market = Market.update(market, :add_period)
      assert length(market.periods) == 2
    end

    test "add an buy_at action to the current period", %{market: market} do
      market = Market.update(market, :buy_at, %{actor: "b1", price: 5})
      action = Market.last_action(market)

      assert action.action == :buy_at
      assert action.params == %{actor: "b1", price: 5}
    end
  end
end
