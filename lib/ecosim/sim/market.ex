defmodule Ecosim.Sim.Market do
  @moduledoc """
  This is the Market simulation. It uses the Vernon Smith protocol
  describeb in `An Experimental Study of Competitive Market Behavior - 1962`.

  Actors are divided in buyers and sellers. They both have a willingness to do something.
  Buyers have a WTB, Willingness To Buy. It's price above which they won't buy.
  Sellers have a WTA, Willingness To Accept to sell. It's a price underneath which they won't sell.

  A simulation is divided in period. which are composed of actions:
  - buy_at: a buyer offers to buy at a price.
  - sell_at: a seller offers to sell at a price.
  - accept the last price.

  An actor can do an action at any given time. When someone accept a price, both the seller and
  the buyer are removed from the period.

  A period ends when action `add_period` is used or when there is no more buyers and sellers.
  Any time a new period is created, buyers and sellers get back to the simulation with the same
  WTA and WTB.
  """
  defstruct buyers: [],
            sellers: [],
            periods: [],
            step: :preparation,
            market_model: 1,
            active_period_index: 0

  alias Ecosim.Sim.Market.Period
  alias Ecosim.Sim.Market.Action
  alias Ecosim.Sim.Market.Actor

  @type t() :: %__MODULE__{
          buyers: [Actor.t()],
          sellers: [Actor.t()],
          periods: [Period.t()],
          step: :preparation | :sim | :result,
          market_model: integer(),
          active_period_index: integer()
        }

  @type action() :: :add_period | :buy_at | :sell_at | :accept

  @type buyers() :: [Actor.t()]
  @type sellers() :: [Actor.t()]
  @type price() :: number()
  @type accept_params() :: %{seller: Actor.t(), buyer: Actor.t(), price: number()}
  @type select_model_params() :: %{market_model: integer()}
  @type transaction() :: [%{index: integer(), price: number()}]
  @type step() :: :preparation | :sim | :result

  @type preparation_info() :: %{
          actors: [Actor.t()],
          step: atom(),
          market_model: integer()
        }
  @type sim_info() :: %{
          transactions: [Action.t()],
          sellers: [%{actor: String.t(), last_offer: number()}],
          buyers: [%{actor: String.t(), last_offer: number()}],
          active_actors: [Actor.t()]
        }

  @type result_info() :: %{
          market_plot: list(),
          price_per_transaction_plot: list(),
          transactions_per_period_plot: list()
        }

  @type change_active_period_params() :: %{
          period: integer()
        }

  @doc """
  Create a new Market with one period from a list of buyers and sellers.
  Or it creates a Market with one period from a list of name and a market model.
  The market model with define what WTs distribution to use.
  """
  @spec new(buyers(), sellers()) :: t()
  def new(buyers, sellers, market_model)
      when is_list(buyers) and is_list(sellers) do
    period = Period.new(buyers ++ sellers)

    %__MODULE__{
      buyers: buyers,
      sellers: sellers,
      periods: [period],
      step: :preparation,
      market_model: market_model,
      active_period_index: 0
    }
  end

  @spec new([String.t()], integer()) :: t()
  def new(actors, market_model)
      when is_integer(market_model) and is_list(actors) do
    {buyers, sellers} =
      actors
      |> spread_actors_between_sellers_and_buyers()
      |> build_wts(market_model)

    period = Period.new(buyers ++ sellers)

    %__MODULE__{
      buyers: buyers,
      sellers: sellers,
      periods: [period],
      step: :preparation,
      market_model: market_model,
      active_period_index: 0
    }
  end

  @spec spread_actors_between_sellers_and_buyers([String.t()]) :: {[String.t()], [String.t()]}
  defp(spread_actors_between_sellers_and_buyers(actors)) do
    half = div(length(actors), 2)

    actors
    |> Enum.split(half)
  end

  @spec build_wts({[String.t()], [String.t()]}, integer()) :: {[Actor.t()], [Actor.t()]}
  defp build_wts({buyers, sellers}, _market_model) do
    price = 100
    step = 2
    {create_buyers(buyers, price, step), create_sellers(sellers, price, step)}
  end

  @spec create_buyers([String.t()], integer(), number()) :: [Actor.t()]
  defp create_buyers(buyers, price, step) do
    start = price + div(length(buyers), 2) * step

    buyers
    |> Enum.map_reduce(start, fn name, wt ->
      {Actor.new(:buyer, name, wt), wt - step}
    end)
    |> elem(0)
  end

  @spec create_sellers([String.t()], integer(), number()) :: [Actor.t()]
  defp create_sellers(sellers, price, step) do
    start = price - div(length(sellers), 2) * step

    sellers
    |> Enum.map_reduce(start, fn name, wt ->
      {Actor.new(:seller, name, wt), wt + step}
    end)
    |> elem(0)
  end

  @doc """
  Create a new Market from the buyers and sellers from another market
  """
  @spec new(t()) :: t()
  def new(%__MODULE__{sellers: sellers, buyers: buyers, market_model: market_model} = _) do
    new(buyers, sellers, market_model)
  end

  defimpl Ecosim.SimulationProtocol do
    @doc """
    Update the market according to the action and params.
    Possible actions `t:action/0`:
    - :add_period: create a new period with the list of actors: buyers ++ sellers
    - :buy_at
    - :sell_at
    - :accept

    ### Params
    It depends on the action.
    - :add_period => no params
    - :buy_at, :sell_at => %{actor: Actor.t(), price: number()}
    - :accept => %{actor: Actor.t()}

    ### Accept

    When an actor accept a price, it will automactillay takes the price depending on what type
    the actor is. If their are buyers, it will take the last seller's price offer and vice versa.
    Then, it creates a transaction action in the list of events and removes both actors from the period
    list of actors.

    If there are no price offers, it returns the market with no modification.

    ### Error
    - :price_not_in_wt: means that for a buyer, price is above WTB, for a seller
                        price is below WTA.
    """
    @spec update(@for.t(), :restart_sim, map()) :: {:ok, @for.t()}
    @spec update(@for.t(), :add_period, map()) :: {:ok, @for.t()}
    @spec update(@for.t(), :undo, map()) :: {:ok, @for.t()}
    @spec update(@for.t(), :step_back, map()) :: {:ok, @for.t()}
    @spec update(@for.t(), :step_forward, map()) :: {:ok, @for.t()}
    # @spec update(@for.t(), :add_actor, add_actor_params()) :: {:ok, @for.t()}
    @spec update(@for.t(), :select_model, @for.select_model_params()) ::
            {:ok, @for.t()} | {:error, :market_model_does_not_exists}
    @spec update(@for.t(), :accept, @for.accept_params()) ::
            {:ok, @for.t()} | {:error, :price_not_in_wt}
    @spec update(@for.t(), :offer, Action.offer_params()) ::
            {:ok, @for.t()} | {:error, :price_not_in_wt}

    @spec update(@for.t(), :change_active_period, @for.change_active_period_params()) ::
            {:ok, @for.t()} | {:error, :out_of_range}

    def update(%@for{} = market, :add_period, _params) do
      {:ok,
       %@for{
         market
         | periods:
             List.insert_at(market.periods, -1, Period.new(market.buyers ++ market.sellers)),
           active_period_index: market.active_period_index + 1
       }}
    end

    def update(%@for{} = market, :undo, _params) do
      {:ok, undo(market)}
    end

    def update(%@for{step: :preparation} = market, :step_back, _params) do
      {
        :ok,
        market
      }
    end

    def update(%@for{step: :sim} = market, :step_back, _params) do
      {:ok,
       %@for{
         market
         | step: :preparation
       }}
    end

    def update(%@for{step: :result} = market, :step_back, _params) do
      {:ok,
       %@for{
         market
         | step: :sim
       }}
    end

    def update(%@for{step: :preparation} = market, :step_forward, _params) do
      {:ok,
       %@for{
         market
         | step: :sim
       }}
    end

    def update(%@for{step: :sim} = market, :step_forward, _params) do
      {:ok,
       %@for{
         market
         | step: :result
       }}
    end

    def update(%@for{step: :result} = market, :step_forward, _params) do
      {
        :ok,
        %@for{
          market
          | step: :result
        }
      }
    end

    def update(%@for{} = market, :restart_sim, _params) do
      {:ok, @for.new(market)}
    end

    def update(%@for{periods: periods} = market, :change_active_period, %{
          period: period_index
        })
        when period_index >= 0 and period_index < length(periods) do
      {
        :ok,
        %@for{
          market
          | active_period_index: period_index
        }
      }
    end

    def update(%@for{} = _, :change_active_period, _), do: {:error, :out_of_range}

    def update(%@for{} = market, :select_model, %{market_model: market_model})
        when market_model in [1, 2, 3] do
      {:ok,
       %@for{
         market
         | market_model: market_model
       }}
    end

    def update(%@for{} = _, :select_model, %{market_model: market_model})
        when market_model not in [1, 2, 3] do
      {:error, :market_model_does_not_exists}
    end

    def update(
          %@for{} = market,
          :accept,
          %{buyer: buyer, seller: seller, price: price}
        ) do
      period_index = market.active_period_index

      if check_wt(buyer, price) && check_wt(seller, price) do
        {:ok,
         %@for{
           market
           | periods:
               List.update_at(market.periods, period_index, fn period ->
                 Period.add_action(period, :accept, %{actors: [seller, buyer], price: price})
               end)
         }}
      else
        {:error, :price_not_in_wt}
      end
    end

    def update(%@for{} = market, :offer, %{actor: actor, price: price} = params) do
      period_index = market.active_period_index
      action = get_specific_action(market, actor)

      if Actor.price_regarding_wt?(actor, price) do
        {:ok,
         %{
           market
           | periods:
               List.update_at(market.periods, period_index, fn period ->
                 Period.add_action(period, action, params)
               end)
         }}
      else
        {:error, :price_not_in_wt}
      end
    end

    @spec check_wt(Actor.t(), number()) :: boolean()
    defp check_wt(%Actor{type: :buyer, wt: wt}, price), do: price <= wt
    defp check_wt(%Actor{type: :seller, wt: wt}, price), do: price >= wt

    @spec get_specific_action(@for.t(), Actor.t()) :: :sell_at | :buy_at
    defp get_specific_action(%@for{} = market, actor) do
      if actor in market.buyers, do: :buy_at, else: :sell_at
    end

    @spec info(@for.t()) :: @for.preparation_info()
    def info(
          %@for{
            step: :preparation,
            sellers: sellers,
            buyers: buyers,
            market_model: market_model
          } =
            _
        ) do
      %{
        actors: sellers ++ buyers,
        market_model: market_model,
        step: :preparation
      }
    end

    @doc """
    Returns information on the market adapted to the simulation step.
    - active actors
    - sellers list
    - buyers list
    - list of transactions
    - periods
    - active current_periods
    """
    @spec info(@for.t()) :: @for.sim_info()
    def info(%@for{step: :sim} = market) do
      active_period(market)
      |> Period.info()
      |> Map.merge(%{
        periods_length: length(market.periods),
        active_period_index: market.active_period_index,
        step: market.step
      })
    end

    @spec info(@for.t()) :: @for.result_info()
    def info(%@for{step: :result} = market) do
      %{
        step: market.step,
        market_plot: market_plot_data(market),
        price_per_transaction_plot: price_per_transaction_plot(market),
        transactions_per_period_plot: transaction_per_period_plot_data(market)
      }
    end

    defp active_period(%@for{} = market) do
      Enum.at(market.periods, market.active_period_index)
    end

    @spec undo(@for.t()) :: @for.t()
    defp undo(%@for{} = market) do
      period_index = market.active_period_index

      periods =
        List.update_at(market.periods, period_index, fn period ->
          period |> Period.remove_last_action()
        end)

      %{market | periods: periods}
    end

    @spec market_plot_data(@for.t()) :: [list()]
    defp market_plot_data(%@for{} = market) do
      sellers =
        Enum.map(market.sellers, & &1.wt)
        |> Enum.sort()
        |> Enum.with_index(fn wt, idx ->
          %{x: idx + 1, y: wt}
        end)

      {buyers, _} =
        Enum.map(market.buyers, & &1.wt)
        |> Enum.sort()
        |> Enum.map_reduce(length(market.buyers), fn wt, acc ->
          {%{x: acc, y: wt}, acc - 1}
        end)

      [buyers, sellers]
    end

    @spec price_per_transaction_plot(@for.t()) :: list()
    defp price_per_transaction_plot(%@for{} = market) do
      Enum.flat_map(market.periods, & &1.actions)
      |> Enum.filter(&(&1.action == :transact))
      |> Enum.with_index(fn %{params: %{price: price}} = _, idx ->
        %{x: idx + 1, y: price}
      end)
    end

    @spec transaction_per_period_plot_data(@for.t()) :: list()
    defp transaction_per_period_plot_data(%@for{} = market) do
      market.periods
      |> Enum.with_index(fn period, idx ->
        quantity =
          Enum.filter(period.actions, &(&1.action == :transact))
          |> length()

        %{x: idx + 1, y: quantity}
      end)
    end
  end
end
