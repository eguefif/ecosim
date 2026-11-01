defmodule Ecosim.MarketTest do
  use Ecosim.DataCase

  alias Ecosim.Market
  alias Ecosim.Market.Actor

  setup do
    buyer = Actor.new(:buyer, "b1", 8)

    buyers = [
      buyer,
      Actor.new(:buyer, "b2", 5)
    ]

    seller = Actor.new(:seller, "s1", 8)

    sellers = [
      seller,
      Actor.new(:seller, "s2", 5)
    ]

    market = Market.new(buyers, sellers)
    [market: market, buyer: buyer, seller: seller]
  end

  describe "Basic Market action" do
    test "add a new period on update :add_period", %{market: market} do
      market = Market.update(market, :add_period)
      assert length(market.periods) == 2
    end

    test "add an buy_at action to the current period", %{
      market: market,
      buyer: buyer
    } do
      market = Market.update(market, :buy_at, %{actor: buyer, price: 5})
      action = Market.last_action(market)

      assert action.action == :buy_at
      assert action.params == %{actor: buyer, price: 5}
    end

    test "add an two actions to the current period", %{
      market: market,
      seller: seller,
      buyer: buyer
    } do
      market = Market.update(market, :sell_at, %{actor: buyer, price: 5})
      %{periods: periods} = Market.update(market, :buy_at, %{actor: seller, price: 3})
      [period] = periods
      [action1, action2] = period.actions

      assert action1.action == :sell_at
      assert action1.params == %{actor: buyer, price: 5}

      assert action2.action == :buy_at
      assert action2.params == %{actor: seller, price: 3}
    end
  end

  describe "buyer takes last seller price" do
    test "do nothing if no seller price", %{market: market, buyer: buyer} do
      market =
        market
        |> Market.update(:accept, %{actor: buyer, price: 5})

      action = Market.last_action(market)

      assert is_nil(action)
    end

    test "add a transaction between b1 and s1", %{market: market, seller: seller, buyer: buyer} do
      market =
        market
        |> Market.update(:sell_at, %{actor: seller, price: 8})
        |> Market.update(:sell_at, %{actor: seller, price: 7})
        |> Market.update(:buy_at, %{actor: buyer, price: 3})
        |> Market.update(:sell_at, %{actor: seller, price: 5})
        |> Market.update(:accept, %{actor: buyer, price: 5})

      action = Market.last_action(market)

      assert action.action == :transact
      assert action.params == %{actors: [buyer, seller], price: 5}
    end

    test "removes both b1 and s1 for the period actors", %{
      market: market,
      seller: seller,
      buyer: buyer
    } do
      [period | _] = market.periods
      actors_length_before = length(period.actors)

      market =
        market
        |> Market.update(:sell_at, %{actor: seller, price: 5})
        |> Market.update(:accept, %{actor: buyer, price: 5})

      [period | _] = market.periods
      actors_length_after = length(period.actors)

      assert actors_length_after != actors_length_before
      assert actors_length_after == 2
      assert seller not in period.actors
      assert buyer not in period.actors
    end
  end

  describe "seller takes last buyer's price" do
    test "do nothing if no buyer's price", %{market: market, seller: seller} do
      market =
        market
        |> Market.update(:accept, %{actor: seller, price: 5})

      action = Market.last_action(market)

      assert is_nil(action)
    end

    test "add a transaction between b1 and s1", %{market: market, seller: seller, buyer: buyer} do
      market =
        market
        |> Market.update(:buy_at, %{actor: buyer, price: 8})
        |> Market.update(:buy_at, %{actor: buyer, price: 7})
        |> Market.update(:sell_at, %{actor: seller, price: 3})
        |> Market.update(:buy_at, %{actor: buyer, price: 5})
        |> Market.update(:accept, %{actor: seller, price: 5})

      action = Market.last_action(market)

      assert action.action == :transact
      assert action.params == %{actors: [seller, buyer], price: 5}
    end

    test "removes both b1 and s1 for the period actors", %{
      market: market,
      seller: seller,
      buyer: buyer
    } do
      [period | _] = market.periods
      actors_length_before = length(period.actors)

      market =
        market
        |> Market.update(:buy_at, %{actor: buyer, price: 5})
        |> Market.update(:accept, %{actor: seller, price: 5})

      [period | _] = market.periods
      actors_length_after = length(period.actors)

      assert actors_length_after != actors_length_before
      assert actors_length_after == 2
      assert seller not in period.actors
      assert buyer not in period.actors
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
end
