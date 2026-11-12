defmodule Ecosim.MarketTest do
  use Ecosim.DataCase

  alias Ecosim.Sim.Market
  alias Ecosim.Sim.Market.Actor

  setup do
    buyer = Actor.new(:buyer, "b1", 8)
    buyer2 = Actor.new(:buyer, "b2", 8)

    buyers = [buyer, buyer2]

    seller = Actor.new(:seller, "s1", 3)
    seller2 = Actor.new(:seller, "s2", 3)

    sellers = [seller, seller2]

    market = Market.new(buyers, sellers)
    [market: market, buyer: buyer, seller: seller, buyer2: buyer2, seller2: seller2]
  end

  describe "Market basic action" do
    test "add a new period on update :add_period", %{market: market} do
      {:ok, market} = Market.update(market, :add_period)
      assert length(market.periods) == 2
    end

    test "add an buy_at action to the current period", %{
      market: market,
      buyer: buyer
    } do
      {:ok, market} = Market.update(market, :offer, %{actor: buyer, price: 5})
      action = Market.actions(market) |> List.last()

      assert action.action == :buy_at
      assert action.params == %{actor: buyer, price: 5}
    end

    test "add an two actions to the current period", %{
      market: market,
      seller: seller,
      buyer: buyer
    } do
      {:ok, market} = Market.update(market, :offer, %{actor: buyer, price: 5})
      {:ok, %{periods: periods}} = Market.update(market, :offer, %{actor: seller, price: 6})
      [period] = periods
      [action1, action2] = period.actions

      assert action1.action == :buy_at
      assert action1.params == %{actor: buyer, price: 5}

      assert action2.action == :sell_at
      assert action2.params == %{actor: seller, price: 6}
    end
  end

  describe "buyer takes last seller price" do
    test "removes both b1 and s1 for the period actors", %{
      market: market,
      seller: seller,
      buyer: buyer
    } do
      [period | _] = market.periods
      actors_length_before = length(period.actors)

      with {:ok, market} <- Market.update(market, :offer, %{actor: seller, price: 5}),
           {:ok, market} <-
             Market.update(market, :accept, %{buyer: buyer, seller: seller, price: 5}) do
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
    test "add a transaction between b1 and s1", %{market: market, seller: seller, buyer: buyer} do
      with {:ok, market} <- Market.update(market, :offer, %{actor: buyer, price: 8}),
           {:ok, market} <- Market.update(market, :offer, %{actor: buyer, price: 7}),
           {:ok, market} <- Market.update(market, :offer, %{actor: seller, price: 3}),
           {:ok, market} <- Market.update(market, :offer, %{actor: buyer, price: 5}),
           {:ok, market} <-
             Market.update(market, :accept, %{buyer: buyer, seller: seller, price: 5}) do
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
             Market.update(market, :offer, %{actor: buyer, price: 5}),
           {:ok, market} <-
             Market.update(market, :accept, %{seller: seller, buyer: buyer, price: 5}) do
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
      {:error, message} = market |> Market.update(:offer, %{actor: buyer, price: 8.01})
      assert message == :price_not_in_wt
    end

    test "a buyer cannot accept a price greater than their WTB", %{
      market: market,
      buyer: buyer,
      seller: seller
    } do
      with {:ok, market} <- Market.update(market, :offer, %{actor: seller, price: 8.01}),
           {:error, message} <-
             Market.update(market, :accept, %{buyer: buyer, seller: seller, price: 8.01}) do
        assert message == :price_not_in_wt
      end
    end

    test "a seller cannot offer a price lesser than their WTA", %{market: market, seller: seller} do
      {result, message} = market |> Market.update(:offer, %{actor: seller, price: 1.01})

      assert result == :error
      assert message == :price_not_in_wt
    end

    test "a seller cannot accept a price lesser than their WTA", %{
      market: market,
      buyer: buyer,
      seller: seller
    } do
      with {:ok, market} <- Market.update(market, :offer, %{actor: buyer, price: 1.01}),
           {:error, message} <-
             Market.update(market, :accept, %{seller: seller, buyer: buyer, price: 1.01}) do
        assert message == :price_not_in_wt
      end
    end
  end

  describe "Complete simulation test" do
    test "That multiple actors make transactions", %{
      market: market,
      buyer: buyer,
      seller: seller,
      buyer2: buyer2,
      seller2: seller2
    } do
      # First round of bid
      market =
        with {:ok, market} <- Market.update(market, :offer, %{actor: seller, price: 6}),
             {:ok, market} <- Market.update(market, :offer, %{actor: seller2, price: 5}),
             {:ok, market} <- Market.update(market, :offer, %{actor: buyer, price: 3}),
             {:ok, market} <- Market.update(market, :offer, %{actor: buyer2, price: 2}),
             {:ok, market} <- Market.update(market, :offer, %{actor: buyer, price: 5}),
             {:ok, market} <-
               Market.update(market, :accept, %{seller: seller, buyer: buyer, price: 5}) do
          period = market.periods |> List.first()
          assert seller2 in period.actors
          assert buyer2 in period.actors
          assert seller not in period.actors
          assert buyer not in period.actors
          [action] = period.actions |> Enum.filter(&(&1.action == :transact))
          assert action.action == :transact
          %{actors: actors, price: price} = action.params
          assert seller in actors
          assert buyer in actors
          assert price == 5

          market
        end

      # Second round of bid
      with {:ok, market} <- Market.update(market, :offer, %{actor: seller2, price: 5}),
           {:ok, market} <- Market.update(market, :offer, %{actor: buyer2, price: 2}),
           {:ok, market} <- Market.update(market, :offer, %{actor: seller2, price: 4}),
           {:ok, market} <-
             Market.update(market, :accept, %{buyer: buyer2, seller: seller2, price: 4}) do
        period = market.periods |> List.first()
        assert seller2 not in period.actors
        assert buyer2 not in period.actors

        actions = period.actions |> Enum.filter(&(&1.action == :transact))
        assert length(actions) == 2

        last_action = actions |> List.last()
        assert last_action.action == :transact
        %{actors: actors, price: price} = last_action.params
        assert seller2 in actors
        assert buyer2 in actors
        assert price == 4
      end
    end
  end

  describe "undo/1" do
    test "removes the last offer on period 2", %{market: market, seller: seller, buyer: buyer} do
      {:ok, market} = Market.update(market, :add_period)
      {:ok, market} = Market.update(market, :offer, %{actor: seller, price: 5})
      {:ok, market} = Market.update(market, :offer, %{actor: buyer, price: 2})

      market = Market.undo(market)
      [_, period] = market.periods

      assert length(period.actions) == 1
      assert length(period.actors) == 4
    end

    test "removes the last transaction on period 2", %{
      market: market,
      seller: seller,
      buyer: buyer
    } do
      {:ok, market} = Market.update(market, :add_period)
      {:ok, market} = Market.update(market, :offer, %{actor: seller, price: 5})
      {:ok, market} = Market.update(market, :offer, %{actor: buyer, price: 8})
      {:ok, market} = Market.update(market, :accept, %{buyer: buyer, seller: seller, price: 8})
      [_, period] = market.periods

      assert length(period.actions) == 3
      assert length(period.actors) == 2

      market = Market.undo(market)
      [_, period] = market.periods

      assert length(period.actions) == 2
      assert length(period.actors) == 4
    end
  end
end
