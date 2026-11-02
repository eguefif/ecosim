defmodule Ecosim.MarketTest do
  use Ecosim.DataCase

  alias Ecosim.Market
  alias Ecosim.Market.Actor

  setup do
    buyer = Actor.new(:buyer, "b1", 8)

    buyers = [
      buyer,
      Actor.new(:buyer, "b2", 10)
    ]

    seller = Actor.new(:seller, "s1", 3)

    sellers = [
      seller,
      Actor.new(:seller, "s2", 2)
    ]

    market = Market.new(buyers, sellers)
    [market: market, buyer: buyer, seller: seller]
  end

  describe "Basic Market action" do
    test "add a new period on update :add_period", %{market: market} do
      {:ok, market} = Market.update(market, :add_period)
      assert length(market.periods) == 2
    end

    test "add an buy_at action to the current period", %{
      market: market,
      buyer: buyer
    } do
      {:ok, market} = Market.update(market, :buy_at, %{actor: buyer, price: 5})
      action = Market.actions(market) |> List.last()

      assert action.action == :buy_at
      assert action.params == %{actor: buyer, price: 5}
    end

    test "add an two actions to the current period", %{
      market: market,
      seller: seller,
      buyer: buyer
    } do
      {:ok, market} = Market.update(market, :sell_at, %{actor: buyer, price: 5})
      {:ok, %{periods: periods}} = Market.update(market, :buy_at, %{actor: seller, price: 6})
      [period] = periods
      [action1, action2] = period.actions

      assert action1.action == :sell_at
      assert action1.params == %{actor: buyer, price: 5}

      assert action2.action == :buy_at
      assert action2.params == %{actor: seller, price: 6}
    end
  end

  describe "buyer takes last seller price" do
    test "do nothing if no seller price", %{market: market, buyer: buyer} do
      {:ok, market} =
        market
        |> Market.update(:accept, %{actor: buyer})

      action = Market.actions(market) |> List.last()

      assert is_nil(action)
    end

    test "add a transaction between b1 and s1", %{market: market, seller: seller, buyer: buyer} do
      with {:ok, market} <- Market.update(market, :sell_at, %{actor: seller, price: 8}),
           {:ok, market} <- Market.update(market, :sell_at, %{actor: seller, price: 7}),
           {:ok, market} <- Market.update(market, :buy_at, %{actor: buyer, price: 3}),
           {:ok, market} <- Market.update(market, :sell_at, %{actor: seller, price: 5}),
           {:ok, market} <- Market.update(market, :accept, %{actor: buyer}) do
        action = Market.actions(market) |> List.last()

        assert action.action == :transact
        assert action.params == %{actors: [buyer, seller], price: 5}
      end
    end

    test "removes both b1 and s1 for the period actors", %{
      market: market,
      seller: seller,
      buyer: buyer
    } do
      [period | _] = market.periods
      actors_length_before = length(period.actors)

      with {:ok, market} <- Market.update(market, :sell_at, %{actor: seller, price: 5}),
           {:ok, market} <- Market.update(market, :accept, %{actor: buyer}) do
        [period | _] = market.periods
        actors_length_after = length(period.actors)

        assert actors_length_after != actors_length_before
        assert actors_length_after == 2
        assert seller not in period.actors
        assert buyer not in period.actors
      end
    end
  end

  describe "seller takes last buyer's price" do
    test "do nothing if no buyer's price", %{market: market, seller: seller} do
      {:ok, market} =
        market
        |> Market.update(:accept, %{actor: seller})

      action = Market.actions(market) |> List.last()

      assert is_nil(action)
    end

    test "add a transaction between b1 and s1", %{market: market, seller: seller, buyer: buyer} do
      with {:ok, market} <- Market.update(market, :buy_at, %{actor: buyer, price: 8}),
           {:ok, market} <- Market.update(market, :buy_at, %{actor: buyer, price: 7}),
           {:ok, market} <- Market.update(market, :sell_at, %{actor: seller, price: 3}),
           {:ok, market} <- Market.update(market, :buy_at, %{actor: buyer, price: 5}),
           {:ok, market} <- Market.update(market, :accept, %{actor: seller}) do
        action = Market.actions(market) |> List.last()

        assert action.action == :transact
        assert action.params == %{actors: [seller, buyer], price: 5}
      end
    end

    test "removes both b1 and s1 for the period actors", %{
      market: market,
      seller: seller,
      buyer: buyer
    } do
      [period | _] = market.periods
      actors_length_before = length(period.actors)

      with {:ok, market} <-
             Market.update(market, :buy_at, %{actor: buyer, price: 5}),
           {:ok, market} <- Market.update(market, :accept, %{actor: seller}) do
        [period | _] = market.periods
        actors_length_after = length(period.actors)

        assert actors_length_after != actors_length_before
        assert actors_length_after == 2
        assert seller not in period.actors
        assert buyer not in period.actors
      end
    end
  end

  describe "WTB/WTA" do
    test "a buyer cannot offer a price greater than their WTB", %{market: market, buyer: buyer} do
      {:error, message} = market |> Market.update(:buy_at, %{actor: buyer, price: 8.01})
      assert message == :price_not_in_wt
    end

    test "a buyer cannot accept a price greater than their WTB", %{
      market: market,
      buyer: buyer,
      seller: seller
    } do
      with {:ok, market} <- Market.update(market, :sell_at, %{actor: seller, price: 8.01}),
           {:error, message} <- Market.update(market, :accept, %{actor: buyer}) do
        assert message == :price_not_in_wt
      end
    end

    test "a seller cannot offer a price lesser than their WTA", %{market: market, seller: seller} do
      {result, message} = market |> Market.update(:sell_at, %{actor: seller, price: 1.01})

      assert result == :error
      assert message == :price_not_in_wt
    end

    test "a seller cannot accept a price lesser than their WTA", %{
      market: market,
      buyer: buyer,
      seller: seller
    } do
      with {:ok, market} <- Market.update(market, :buy_at, %{actor: buyer, price: 1.01}),
           {:error, message} <- Market.update(market, :accept, %{actor: seller}) do
        assert message == :price_not_in_wt
      end
    end
  end
end
