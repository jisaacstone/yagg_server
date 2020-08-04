alias Yagg.Unit
alias Yagg.Board
alias Yagg.AI.Choices
alias Yagg.Board.Action
require Helper.Board
#alias Yagg.Board.State.Placement

defmodule YaggTest.AI do
  use ExUnit.Case
  require Helper.Board, as: HB

  def possible_actions(board, position) do
    Enum.flat_map(board.grid,
    fn
      ({coords, %Unit{position: ^position}}) ->
      # TODO: add unit ability actions
      Enum.map(Board.Grid.surrounding(coords), fn ({x, y}) ->
        %Action.Move{from_x: x, from_y: y, to_x: x, to_y: y}
      end)
      ({_, _}) -> []
    end)
  end

  test "possible moves" do
    board =
      HB.new_board() |>
      Map.put(:state, :battle) |>
      Board.place!(Unit.new(:north, :test, 3, 3), {2, 4}) |>
      Board.place!(Unit.new(:south, :test, 3, 3), {1, 1})

    actions = possible_actions(board, :north)
    assert Enum.count(actions) == 4
  end

  test "placement" do
    board = HB.new_board(
      [Unit.Monarch.new(:nil)],
      [],
      {4, 4}
    )
    choices = Choices.choices(board, :north)
    assert Enum.member?(choices.place, %Action.Place{index: 0, x: 3, y: 3})
    assert not(Enum.member?(choices.place, %Action.Place{index: 0, x: 0, y: 0}))
    assert choices.move == []
    assert choices.ability == []
  end
  
  test "placement occupied" do
    board = HB.new_board(
      [Unit.Monarch.new(:nil)],
      [{{3, 3}, :water}],
      {4, 4}
    )
    choices = Choices.choices(board, :north)
    assert not(Enum.member?(choices.place, %Action.Place{index: 0, x: 3, y: 3}))
  end

  test "move" do
    board = 
      HB.new_board([], [], {4, 4})
      |> Map.put(:state, :battle)
      |> Board.place!(Unit.Monarch.new(:north), {3, 3})
    choices = Choices.choices(board, :north)
    assert Enum.member?(choices.move, %Action.Move{from_x: 3, from_y: 3, to_x: 3, to_y: 2})
    assert choices.place == []
    assert choices.ability == []
  end

  test "ability" do
    board = 
      HB.new_board([], [], {4, 4})
      |> Map.put(:state, :battle)
      |> Board.place!(Unit.Pushie.new(:north), {3, 3})
    choices = Choices.choices(board, :north)
    assert Enum.member?(choices.ability, %Action.Ability{x: 3, y: 3})
    assert choices.place == []
  end
end
