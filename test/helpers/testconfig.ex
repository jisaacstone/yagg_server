alias Yagg.Board.Configuration
alias Yagg.Board

defmodule Helper.TestConfig do
  @behavior Configuration

  @impl Configuration
  def new() do
    %Configuration{
      dimensions: {5, 5},
      initial_module: Board,
      army_size: 8,
      units: %{north: [], south: []},
      terrain: [],
    }
  end
end
