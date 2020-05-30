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
          [Event.new(position, :unit_assigned, %{index: act.index, x: act.x, y: act.y})]
        }
      err -> err
    end
  end

  def resolve(act, %Board{state: :battle} = board, position) do
    {{unit, :nil}, hand} = Map.pop(board.hands[position], act.index)
    case Board.place(board, unit, {act.x, act.y}) do
      {:ok, board} ->
        {
          %{board | hands: %{board.hands | position => hand}},
          [
            Event.new(position, :unit_assigned, %{index: act.index, x: act.x, y: act.y}),
            Event.new(:global, :unit_placed, %{x: act.x, y: act.y, player: position}),
          ]
        }
      err -> err
    end
  end
end