alias Yagg.Board
alias Yagg.Board.State.Gameover
alias Yagg.Board.Action
alias Yagg.Table.Player

defmodule Board.Action.Concede do
  @behaviour Action
  defstruct reason: "conceded"

  @impl Action
  def resolve(_, %Board{state: %Gameover{}}, _) do
    {:err, :gameover}
  end
  def resolve(con, %Board{} = board, position) do
    {grid, events} = Board.Grid.reveal_units(board.grid)
    board = %{board | state: %Gameover{winner: Player.opposite(position), reason: con.reason}, grid: grid}
    {board, events}
  end
  def resolve(_, _, _) do
    {:err, :not_started}
  end
end
