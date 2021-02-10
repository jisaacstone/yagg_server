alias Yagg.Unit
alias Yagg.Board.Grid
alias Yagg.Table.Player
alias Yagg.Board.State

defmodule Unit.Ability.Concede do
  @moduledoc "Lose the game"
  use Unit.Ability

  def resolve(%{state: %State.Gameover{winner: winner}} = board, opts) do
    case Player.opposite(opts[:unit].position) do
      ^winner -> {board, []}
      _ -> {%{board | state: Map.put(board.state, :winner, :draw)}, []}
    end
  end
  def resolve(board, opts) do
    {grid, events} = Grid.reveal_units(board.grid)
    winner = Player.opposite(opts[:unit].position)
    board = %{board | state: %State.Gameover{winner: winner}, grid: grid}
    {board, events}
  end
end

