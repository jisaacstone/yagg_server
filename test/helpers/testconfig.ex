alias Yagg.Board.Configuration
alias Yagg.Board

defmodule Helper.TestConfig do
  @behaviour Configuration

  def name(), do: :testconfig
  def description(), do: "testconfig"

  @impl Configuration
  def new() do
    %Configuration{
      name: :testconfig,
      dimensions: {5, 5},
      initial_module: Board,
      army_size: 8,
      units: %{north: [], south: []},
      terrain: [],
    }
  end
end
