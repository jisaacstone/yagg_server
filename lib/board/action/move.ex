alias Yagg.Board
alias Yagg.Board.Action

defmodule Action.Move do
  @behaviour Action
  @enforce_keys [:from_x, :from_y, :to_x, :to_y]
  defstruct @enforce_keys
 
  @impl Action
  def resolve(move, %Board{state: :battle} = board, position) do
    case Board.move(board, position, {move.from_x, move.from_y}, {move.to_x, move.to_y}) do
      {:err, _} = err ->
        err
      {board, events} ->
        {board, events}
    end
  end
  def resolve(_, _, _) do
    {:err, :badstate}
  end
end
