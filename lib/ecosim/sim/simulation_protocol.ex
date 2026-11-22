defprotocol Ecosim.Sim.SimulationProtocol do
  @type t() :: Ecosim.Sim.Market.t()

  @spec update(t(), atom(), map()) :: {:ok, t()} | {:error, term}
  def update(sim, command, params)

  @spec info(t()) :: map()
  def info(sim)
end
