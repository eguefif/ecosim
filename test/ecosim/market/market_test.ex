defmodule Ecosim.MarketTest do
  use Ecosim.DataCase

  alias Ecosim.Market

  describe "Basic Market action" do
    setup do
      buyers = ["b1", "b3"]
      sellers = ["s1", "s2"]
      market = Market.new(buyers, sellers)
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
      %{periods: periods} = Market.update(market, :buy_at, %{actor: "s2", price: 3})
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
        Market.new(buyers, sellers)

      [market: market]
    end

    test "do nothing if no seller price", %{market: market} do
      market =
        market
        |> Market.update(:accept, %{actor: "b1", price: 5})

      action = Market.last_action(market)

      assert is_nil(action)
    end

    test "add a transaction between b1 and s1", %{market: market} do
      market =
        market
        |> Market.update(:sell_at, %{actor: "s1", price: 8})
        |> Market.update(:sell_at, %{actor: "s1", price: 7})
        |> Market.update(:buy_at, %{actor: "b1", price: 3})
        |> Market.update(:sell_at, %{actor: "s1", price: 5})
        |> Market.update(:accept, %{actor: "b1", price: 5})

      action = Market.last_action(market)

      assert action.action == :transact
      assert action.params == %{actors: ["b1", "s1"], price: 5}
    end
  end

  describe "seller takes last buyer's price" do
    setup do
      buyers = ["b1", "b3"]
      sellers = ["s1", "s2"]

      market =
        Market.new(buyers, sellers)

      [market: market]
    end

    test "do nothing if no buyer's price", %{market: market} do
      market =
        market
        |> Market.update(:accept, %{actor: "s1", price: 5})

      action = Market.last_action(market)

      assert is_nil(action)
    end

    test "add a transaction between b1 and s1", %{market: market} do
      market =
        market
        |> Market.update(:buy_at, %{actor: "b1", price: 8})
        |> Market.update(:buy_at, %{actor: "b1", price: 7})
        |> Market.update(:sell_at, %{actor: "s1", price: 3})
        |> Market.update(:buy_at, %{actor: "b1", price: 5})
        |> Market.update(:accept, %{actor: "s1", price: 5})

      action = Market.last_action(market)

      assert action.action == :transact
      assert action.params == %{actors: ["s1", "b1"], price: 5}
    end
  end

  describe "WTB/WTA" do
    @tag :skip
    test "a buyer cannot offer a price greater than their WTB" do
    end

    @tag :skip
    test "a seller cannot offer a price lesser than their WTA" do
    end
  end

  describe "Period" do
    @tag :skip
    test "A period stop after XX actions with no transaction and at least 1 action" do
    end
  end

  describe "Market" do
    @tag :skip
    test "A Market simulation stops when there is 5 periods by default" do
    end
  end
end
