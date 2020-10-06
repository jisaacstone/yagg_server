alias Yagg.Board
alias Yagg.Board.Action
alias Yagg.Board.State
alias Yagg.Event

defmodule Action.Place do
  @behaviour Action
  @enforce_keys [:index, :x, :y]
  defstruct @enforce_keys

  @impl Action
  def resolve(_, %Board{state: %State.Placement{ready: position}}, position) do
    {:err, :already_ready}
  end
  def resolve(act, %Board{state: %State.Placement{}} = board, position) do
    case Board.assign(board, position, act.index, {act.x, act.y}) do
      {:ok, board} -> 
        {
          board,
          [Event.UnitAssigned.new(position, index: act.index, x: act.x, y: act.y)]
        }
      err -> err
    end
  end
  def resolve(act, %Board{state: :battle} = board, position) do
    case Map.pop(board.hands[position], act.index) do
      {:nil, _} -> {:err, :already_placed}
      {{unit, :nil}, hand} ->
        case Board.place(board, unit, {act.x, act.y}) do
          {:err, _} = err -> err
          {:ok, board} ->
            {
              %{board | hands: %{board.hands | position => hand}},
              [
                Event.UnitAssigned.new(position, index: act.index, x: act.x, y: act.y),
                Event.UnitPlaced.new(x: act.x, y: act.y, player: position),
              ]
            }
        end
    end
  end
  def resolve(_, _, _) do
    {:err, :badstate}
  end
end
