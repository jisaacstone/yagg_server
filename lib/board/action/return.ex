alias Yagg.Board
alias Yagg.Board.Action
alias Yagg.Board.State
alias Yagg.Event

defmodule Action.Return do
  @behaviour Action
  @enforce_keys [:index]
  defstruct @enforce_keys

  @impl Action
  def resolve(_, %Board{state: %State.Placement{ready: position}}, position) do
    {:err, :already_ready}
  end

  def resolve(%{index: index}, %Board{state: %State.Placement{}, hands: hands} = board, position) do
    case hands[position][index] do
      :nil -> {:err, :badindex}
      {_unit, :nil} -> {:err, :notassigned}
      {unit, {x, y}} ->
        {hand, events} = Board.Hand.add_unit_at(
          hands[position],
          index,
          unit,
          [Event.ThingMoved.new(position, from: {x, y}, to: :hand)]
        )
        board = %{board | hands: Map.put(hands, position, hand)}
        {board, events}
    end
  end

  def resolve(_, _, _) do
    {:err, :badstate}
  end
end
