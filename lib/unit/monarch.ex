alias Yagg.Unit
alias Yagg.Board.Grid
alias Yagg.Board.State.Gameover
alias Yagg.Board.Action.Ability.AfterMove

defmodule Unit.Monarch do
  @behaviour Unit
  @impl Unit
  def new(position) do
    Unit.new(
      position: position,
      name: :monarch,
      monarch: :true,
      attack: 1,
      defense: 0,
      triggers: %{
        death: Unit.Ability.Concede,
        move: Unit.Monarch.Cross,
      }
    )
  end

  defmodule Cross do
    @moduledoc """
    Cross the board to the far side to win
    """
    use AfterMove
    @impl AfterMove
    def after_move(board, data) do
      if accross(board.dimensions, data.unit.position, data.to) do
        {grid, events} = Grid.reveal_units(board.grid)
        board = %{board | state: %Gameover{winner: data.unit.position}, grid: grid}
        {board, events}
      else
        {board, []}
      end
    end

    defp accross(_, :north, {_, 0}), do: :true
    defp accross({_, h}, :south, {_, y}) when y == h - 1, do: :true
    defp accross(_, _, _), do: :false
  end
end
