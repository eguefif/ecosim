defprotocol Ecosim.SimulationProtocol do
  @spec update(t(), atom(), map()) :: {:ok, t()} | {:error, term}
  def update(sim, command, params)

  @spec info(t()) :: t()
  def info(sim)
end
