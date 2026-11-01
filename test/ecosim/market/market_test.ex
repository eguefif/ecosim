defmodule Ecosim.MarketTest do
  use Ecosim.DataCase

  alias Ecosim.Market

  describe "Basic Market action" do
    setup do
      buyers = ["b1", "b3"]
      sellers = ["s1", "s2"]
      market = Market.create(buyers, sellers)
      [market: market]
    end

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

    test "add an two actions to the current period", %{market: market} do
      market = Market.update(market, :sell_at, %{actor: "b1", price: 5})
      %{periods: periods} = market = Market.update(market, :buy_at, %{actor: "s2", price: 3})
      [period] = periods
      [action1, action2] = period.actions

      assert action1.action == :sell_at
      assert action1.params == %{actor: "b1", price: 5}

      assert action2.action == :buy_at
      assert action2.params == %{actor: "s2", price: 3}
    end
  end

  describe "buyer takes last seller price" do
    setup do
      buyers = ["b1", "b3"]
      sellers = ["s1", "s2"]

      market =
        Market.create(buyers, sellers)
        |> Market.update(:sell_at, %{actor: "b1", price: 8})
        |> Market.update(:sell_at, %{actor: "b1", price: 7})
        |> Market.update(:buy_at, %{actor: "s1", price: 3})
        |> Market.update(:sell_at, %{actor: "b1", price: 5})
        |> Market.update(:accept, %{actor: "s1", price: 5})

      [market: market]
    end

    test "add a transaction between b1 and s1", %{market: market} do
      action = Market.last_action(market)

      assert action.action == :transact
      assert action.params == %{seller: "s1", buyer: "b1", price: 5}
    end
  end
end
