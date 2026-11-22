defmodule Ecosim.Market.ActorsFileTest do
  use ExUnit.Case, async: true

  alias Ecosim.Sim.Market
  alias Ecosim.Sim.Market.Actor
  alias Ecosim.Sim.Market.ActorsFile
  alias Ecosim.SimulationProtocol

  describe "encode/1" do
    test "writes a header and one line per actor, buyers first" do
      actors = [Actor.new(:seller, "David", 98), Actor.new(:buyer, "Alice", 102.5)]

      assert ActorsFile.encode(actors) == "role,name,wt\nbuyer,Alice,102.5\nseller,David,98\n"
    end

    test "round-trips through decode/1" do
      market = Market.new(["Alice", "Bruno", "Chloé", "David", "Émilie", "François"], 1)

      assert {:ok, %{buyers: buyers, sellers: sellers}} =
               market.buyers
               |> Kernel.++(market.sellers)
               |> ActorsFile.encode()
               |> ActorsFile.decode()

      assert buyers == market.buyers
      assert sellers == market.sellers
    end
  end

  describe "decode/1" do
    test "parses buyers and sellers, without a header, ignoring blank lines and spaces" do
      content = "\nBuyer , Alice, 102\r\n\nvendeur,David,98.5\n"

      assert {:ok, %{buyers: [alice], sellers: [david]}} = ActorsFile.decode(content)
      assert alice == Actor.new(:buyer, "Alice", 102)
      assert david == Actor.new(:seller, "David", 98.5)
    end

    test "ignores a UTF-8 byte order mark" do
      assert {:ok, _} = ActorsFile.decode("﻿role,name,wt\nbuyer,A,1\nseller,B,2\n")
    end

    test "reports the line number of invalid lines, counting header and blank lines" do
      assert ActorsFile.decode("role,name,wt\nbuyer,A,1\n\nseller,B\n") ==
               {:error, {:invalid_line, 4}}

      assert ActorsFile.decode("buyer,A,1\nboss,B,2\n") == {:error, {:invalid_role, 2}}
      assert ActorsFile.decode("buyer, ,1\n") == {:error, {:invalid_name, 1}}
      assert ActorsFile.decode("buyer,A,abc\n") == {:error, {:invalid_wt, 1}}
      assert ActorsFile.decode("buyer,A,12abc\n") == {:error, {:invalid_wt, 1}}
    end

    test "rejects files without actors, buyers or sellers, or with duplicate names" do
      assert ActorsFile.decode("role,name,wt\n") == {:error, :empty}
      assert ActorsFile.decode("seller,A,1\n") == {:error, :no_buyers}
      assert ActorsFile.decode("buyer,A,1\n") == {:error, :no_sellers}
      assert ActorsFile.decode("buyer,A,1\nseller,A,2\n") == {:error, {:duplicate_name, "A"}}
    end
  end

  describe "SimulationProtocol.update/3 with :set_actors" do
    setup do
      %{market: Market.new(["Alice", "Bruno", "Chloé", "David"], 2)}
    end

    test "replaces the actors and keeps the market model", %{market: market} do
      buyers = [Actor.new(:buyer, "Zoé", 120)]
      sellers = [Actor.new(:seller, "Yann", 80)]

      assert {:ok, updated} =
               SimulationProtocol.update(market, :set_actors, %{buyers: buyers, sellers: sellers})

      assert updated.buyers == buyers
      assert updated.sellers == sellers
      assert updated.market_model == 2
      assert [%{actors: [_, _]}] = updated.periods
    end

    test "is refused once the simulation started", %{market: market} do
      {:ok, market} = SimulationProtocol.update(market, :step_forward, %{})

      assert SimulationProtocol.update(market, :set_actors, %{buyers: [], sellers: []}) ==
               {:error, :not_in_preparation}
    end
  end
end
