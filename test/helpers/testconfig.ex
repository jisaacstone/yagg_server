alias Yagg.Board.Configuration
alias Yagg.Board

defmodule Helper.TestConfig do
  @behaviour Configuration

  @impl Configuration
  def name(), do: :testconfig

  @impl Configuration
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
