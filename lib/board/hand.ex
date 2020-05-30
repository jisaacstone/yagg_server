alias Yagg.Board
alias Yagg.Unit
alias Yagg.Event
alias Yagg.Table.Player

defmodule Yagg.Board.Hand do
  @type t() :: %{non_neg_integer() => {Unit.t, :nil | Board.coord()}}

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
  defp add_unit_at(hand, index, %Unit{} = unit, notifications \\ []) do
    {
      Map.put_new(hand, index, {unit, :nil}),
      [Event.new(unit.position, :new_hand, %{unit: unit, index: index}) | notifications]
    }
  end

  @spec new(Player.position(), [Event.t], module()) :: {t(), [Event.t]}
  def new(position, notifications, configuration) do
    {_, hand, notif} = Enum.reduce(
      configuration.starting_units(position),
      {0, %{}, notifications},
      fn (unit, {i, h, n}) ->
        {h2, n2} = add_unit_at(h, i, unit, n)
        {i + 1, h2, n2}
      end
    )
    {hand, notif}
  end
end
