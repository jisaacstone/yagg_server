alias Yagg.Board.Unit
alias Yagg.Board
alias Yagg.Board.Actions.Ability
alias Yagg.Board.State.Placement

defmodule YaggTest.Action.Place do
  use ExUnit.Case

  test "place unit" do
    unit = Unit.new(:north, :test, 3, 3)
    board = %{Board.new() | state: %Placement{}}
    hands = Map.put(board.hands, :north, %{0 => {unit, :nil}})
    board = %{board | hands: hands}
    action = %Board.Actions.Place{index: 0, x: 4, y: 4}
    assert {newboard, _events} = Board.Actions.resolve(action, board, :north)
    assert newboard.hands[:north][0] == {unit, {4, 4}}
  end

  test "place battle" do
    unit = Unit.new(:north, :test, 3, 3)
    board = %{Board.new() | state: :battle}
    hands = Map.put(board.hands, :north, %{0 => {unit, :nil}})
    board = %{board | hands: hands}
    action = %Board.Actions.Place{index: 0, x: 4, y: 4}
    assert {%{grid: grid, hands: hands}, _events} = Board.Actions.resolve(action, board, :north)
    assert hands[:north][0] == :nil
    assert grid[{4, 4}] == unit
  end
end

defmodule YaggTest.Action.Move do
  use ExUnit.Case

  test "move unit" do
    unit = Unit.new(:north, :test, 3, 3)
    board =
      Board.new() |>
      Map.put(:state, :battle) |>
      Board.place(unit, {2, 4}) |> elem(1)

    action = %Board.Actions.Move{from_x: 2, from_y: 4, to_x: 2, to_y: 3}
    assert {newboard, events} = Board.Actions.resolve(action, board, :north)
    assert newboard.grid[{2, 3}] == unit
    assert Enum.find(events, fn(e) -> e.kind == :unit_moved end)
  end

  test "attack" do
    attacker = Unit.new(:north, :test, 3, 3)
    defender = Unit.new(:south, :t2, 1, 1)
    board =
      Board.new()
      |> Map.put(:state, :battle)
      |> Board.place(attacker, {4, 4}) |> elem(1)
      |> fn (b) -> %{b | grid: Map.put(b.grid, {4, 3}, defender)} end.()
    action = %Board.Actions.Move{from_x: 4, from_y: 4, to_x: 4, to_y: 3}
    assert {newboard, events} = Board.Actions.resolve(action, board, :north)
    assert newboard.grid[{4, 3}] == attacker
    assert Enum.find(events, fn(e) -> e.kind == :unit_died end)
  end
 
  test "attackyourself" do
    unit = Unit.new(:north, :test, 3, 3)
    unit2 = Unit.new(:north, :test2, 3, 3)
    board =
      Board.new()
      |> Map.put(:state, :battle)
      |> Board.place(unit, {4, 4}) |> elem(1)
      |> Board.place(unit2, {4, 3}) |> elem(1)
    action = %Board.Actions.Move{from_x: 4, from_y: 4, to_x: 4, to_y: 3}
    assert {:err, :noselfattack} = Board.Actions.resolve(action, board, :north)
  end
end

defmodule YaggTest.Action.Ready do
  use ExUnit.Case

  test "ready" do
    unit = Unit.new(:north, :monarch, 3, 3)
    board = %{Board.new() | state: %Placement{}}
    hands = Map.put(board.hands, :north, %{0 => {unit, {4, 4}}})
    board = %{board | hands: hands}
    action = %Board.Actions.Ready{}
    assert {newboard, [event]} = Board.Actions.resolve(action, board, :north)
    assert %Placement{ready: :north} == newboard.state
    assert %{player: :north} = event.data
  end

  test "gamestart" do
    unit = Unit.new(:north, :monarch, 3, 3)
    board = %{Board.new() | state: %Placement{ready: :south}}
    hands = Map.put(board.hands, :north, %{0 => {unit, {4, 4}}})
    board = %{board | hands: hands}
    action = %Board.Actions.Ready{}
    assert {newboard, _events} = Board.Actions.resolve(action, board, :north)
    assert :battle == newboard.state
    assert unit == newboard.grid[{4, 4}]
  end
end

defmodule YaggTest.Action.Ability do
  use ExUnit.Case

  test "selfdestruct" do
    unit = Unit.new(:north, :test, 3, 3, Ability.Selfdestruct)
    unit2 = Unit.new(:north, :test2, 3, 3)
    board =
      Board.new()
      |> Map.put(:state, :battle)
      |> Board.place(unit, {4, 4}) |> elem(1)
      |> Board.place(unit2, {4, 3}) |> elem(1)
    action = %Board.Actions.Ability{name: "selfdestruct", x: 4, y: 4}
    assert {%Board{} = newboard, events} = Board.Actions.resolve(action, board, :north)
    assert newboard.grid[{4, 4}] == :nil
    assert newboard.grid[{4, 3}] == :nil
    assert Enum.find(events, fn(e) -> e.kind == :unit_died end)
  end
end
