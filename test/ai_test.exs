alias Yagg.Unit
alias Yagg.Board
#alias Yagg.Board.Action.Ability
#alias Yagg.Board.State.Placement

defmodule YaggTest.AI do
  use ExUnit.Case

  def possible_actions(board, position) do
    Enum.flat_map(board.grid,
    fn
      ({coords, %Unit{position: ^position}}) ->
      # TODO: add unit ability actions
      Enum.map(Board.Grid.surrounding(coords), fn ({x, y}) ->
        %Board.Action.Move{from_x: x, from_y: y, to_x: x, to_y: y}
      end)
      ({_, _}) -> []
    end)
  end

  test "possible moves" do
    board =
      Board.new() |>
      Map.put(:state, :battle) |>
      Board.place!(Unit.new(:north, :test, 3, 3), {2, 4}) |>
      Board.place!(Unit.new(:south, :test, 3, 3), {1, 1})

    actions = possible_actions(board, :north)
    assert Enum.count(actions) == 4
  end

end
