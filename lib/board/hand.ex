alias Yagg.Board
alias Yagg.Unit
alias Yagg.Event

defmodule Yagg.Board.Hand do
  @type t() :: %{non_neg_integer() => {Unit.t, :nil | Board.Grid.coord()}}

  def add_unit(%Board{} = board, position, %Unit{} = unit) do
    {hand, events} = board.hands[position] |> add_unit(unit)
    {%{board | hands: Map.put(board.hands, position, hand)}, events}
  end
  def add_unit(hand, %Unit{} = unit) do
    index = case Enum.empty?(hand) do
      :true -> 0
      :false -> hand |> Map.keys() |> Enum.max() |> Kernel.+(1)
    end
    add_unit_at(hand, index, unit)
  end

  @spec new([Unit.t], [Event.t]) :: {t(), [Event.t]}
  def new(units, notifications) do
    {_, hand, notif} = Enum.reduce(
      units,
      {0, %{}, notifications},
      fn (unit, {i, h, n}) ->
        {h2, n2} = add_unit_at(h, i, unit, n)
        {i + 1, h2, n2}
      end
    )
    {hand, notif}
  end

  def add_unit_at(hand, index, %Unit{} = unit, notifications \\ []) do
    {
      Map.put(hand, index, {unit, :nil}),
      [Event.AddToHand.new(unit.position, unit: unit, index: index) | notifications]
    }
  end
end
