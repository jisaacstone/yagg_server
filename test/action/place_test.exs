alias Yagg.Unit
alias Yagg.Board
alias Yagg.Board.State.Placement
import Helper.Board

defmodule YaggTest.Action.Place do
  use ExUnit.Case

  test "place unit" do
    unit = Unit.new(:north, :test, 3, 3)
    board = %{new_board() | state: %Placement{}}
    hands = Map.put(board.hands, :north, %{0 => {unit, :nil}})
    board = %{board | hands: hands}
    action = %Board.Action.Place{index: 0, x: 4, y: 4}
    assert {newboard, _events} = Board.Action.resolve(action, board, :north)
    assert newboard.hands[:north][0] == {unit, {4, 4}}
  end

  test "place unit occupied" do
    unit = Unit.new(:north, :test, 3, 3)
    board = new_board()
    hands = Map.put(board.hands, :north, %{0 => {unit, :nil}})
    board = %{board | hands: hands, grid: %{{4, 4} => :water}}
    action = %Board.Action.Place{index: 0, x: 4, y: 4}
    assert {:err, :occupied} = Board.Action.resolve(action, board, :north)
  end

  test "place battle" do
    unit = Unit.new(:north, :test, 3, 3)
    board = %{new_board() | state: :battle}
    hands = Map.put(board.hands, :north, %{0 => {unit, :nil}})
    board = %{board | hands: hands}
    action = %Board.Action.Place{index: 0, x: 4, y: 4}
    assert {%{grid: grid, hands: hands}, _events} = Board.Action.resolve(action, board, :north)
    assert hands[:north][0] == :nil
    assert grid[{4, 4}] == unit
  end

  test "already_assigned" do
    unit = Unit.new(:north, :test, 3, 3)
    board = new_board()
    hands = Map.put(board.hands, :north, %{0 => {unit, :nil}})
    board = %{board | hands: hands}
    action = %Board.Action.Place{index: 0, x: 4, y: 4}
    assert {newboard, _events} = Board.Action.resolve(action, board, :north)
    assert {:err, _} = Board.Action.resolve(action, newboard, :north)
  end

  test "occupied" do
    unit1 = Unit.new(:north, :test1, 3, 3)
    unit2 = Unit.new(:north, :test2, 3, 3)
    board = new_board()
    hands = Map.put(board.hands, :north, %{0 => {unit1, :nil}, 1 => {unit2, :nil}})
    board = %{board | hands: hands}
    action = %Board.Action.Place{index: 0, x: 4, y: 4}
    assert {newboard, _events} = Board.Action.resolve(action, board, :north)
    action = %Board.Action.Place{index: 1, x: 4, y: 4}
    assert {:err, _} = Board.Action.resolve(action, newboard, :north)
  end
end

