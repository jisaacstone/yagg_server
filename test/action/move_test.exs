alias Yagg.Unit
alias Yagg.Board
alias Yagg.Board.Action.Ability
import Helper.Board

defmodule YaggTest.Action.Move do
  use ExUnit.Case

  test "move unit" do
    unit = Unit.new(:north, :test, 3, 3)
    board =
      new_board() |>
      Map.put(:state, :battle) |>
      Board.place(unit, {2, 4}) |> elem(1)

    action = %Board.Action.Move{from_x: 2, from_y: 4, to_x: 2, to_y: 3}
    assert {newboard, events} = Board.Action.resolve(action, board, :north)
    assert newboard.grid[{2, 3}] == unit
    assert Enum.find(events, fn(e) -> e.kind == :thing_moved end)
  end

  test "attack" do
    attacker = Unit.new(:north, :test, 3, 3)
    defender = Unit.new(:south, :t2, 1, 1)
    board =
      new_board()
      |> Map.put(:state, :battle)
      |> Board.place(attacker, {4, 4}) |> elem(1)
      |> fn (b) -> %{b | grid: Map.put(b.grid, {4, 3}, defender)} end.()
    action = %Board.Action.Move{from_x: 4, from_y: 4, to_x: 4, to_y: 3}
    assert {newboard, events} = Board.Action.resolve(action, board, :north)
    assert newboard.grid[{4, 3}] == attacker
    assert Enum.find(events, fn(e) -> e.kind == :unit_died end)
  end

  test "winner winner chicken dinner" do
    attacker = Unit.new(:north, :test, 3, 3)
    defender = Unit.new(:south, :monarch, 1, 1, :nil, %{death: Ability.Concede})
    board =
      new_board()
      |> Map.put(:state, :battle)
      |> Board.place(attacker, {4, 4}) |> elem(1)
      |> fn (b) -> %{b | grid: Map.put(b.grid, {4, 3}, defender)} end.()
    action = %Board.Action.Move{from_x: 4, from_y: 4, to_x: 4, to_y: 3}
    assert {newboard, events} = Board.Action.resolve(action, board, :north)
    assert newboard.grid[{4, 3}] == attacker
    assert Enum.find(events, fn(e) -> e.kind == :unit_died end)
    gameover = Enum.find(events, fn(e) -> e.kind == :gameover end)
    assert gameover.data.winner == :north
  end
 
  test "attackyourself" do
    unit = Unit.new(:north, :test, 3, 3)
    unit2 = Unit.new(:north, :test2, 3, 3)
    board =
      new_board()
      |> Map.put(:state, :battle)
      |> Board.place(unit, {4, 4}) |> elem(1)
      |> Board.place(unit2, {4, 3}) |> elem(1)
    action = %Board.Action.Move{from_x: 4, from_y: 4, to_x: 4, to_y: 3}
    assert {:err, :noselfattack} = Board.Action.resolve(action, board, :north)
  end

  test "push block" do
    unit = Unit.new(:north, :test, 3, 3)
    board =
      new_board()
      |> Map.put(:state, :battle)
      |> Board.place(unit, {2, 3}) |> elem(1)
      |> fn (b) -> %{b | grid: Map.put(b.grid, {2, 2}, :block)} end.()
    action = %Board.Action.Move{from_x: 2, from_y: 3, to_x: 2, to_y: 2}
    assert {newboard, _events} = Board.Action.resolve(action, board, :north)
    assert newboard.grid[{2, 2}] == unit
    assert newboard.grid[{2, 1}] == :block
  end
end
