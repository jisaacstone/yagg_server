alias Yagg.Unit
alias Yagg.Event
alias Yagg.Table.Player
alias Yagg.Board.Grid

defmodule Unit.Ability do
  def reveal({x, y}, board, position, events \\ []) do
    enemy = Player.opposite(position)
    {board, events} = case board.grid[{x, y}] do
      %Unit{visible: :all} -> {board, events}
      %Unit{position: ^enemy} ->
        Grid.update(
          board,
          {x, y},
          fn(u) -> %{u | visible: :all} end,
          [Event.AbilityUsed.new(position, type: :scan, x: x, y: y) | events]
        )
      _ -> {board, events}
    end
    {board, events}
  end
end
