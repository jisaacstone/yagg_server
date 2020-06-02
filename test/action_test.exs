alias Yagg.Unit
alias Yagg.Board
alias Yagg.Board.Action.Ability
alias Yagg.Board.State.Placement

defmodule YaggTest.Action.Place do
  use ExUnit.Case

  test "place unit" do
    unit = Unit.new(:north, :test, 3, 3)
    board = %{Board.new() | state: %Placement{}}
    hands = Map.put(board.hands, :north, %{0 => {unit, :nil}})
    board = %{board | hands: hands}
    action = %Board.Action.Place{index: 0, x: 4, y: 4}
    assert {newboard, _events} = Board.Action.resolve(action, board, :north)
    assert newboard.hands[:north][0] == {unit, {4, 4}}
  end

  test "place battle" do
    unit = Unit.new(:north, :test, 3, 3)
    board = %{Board.new() | state: :battle}
    hands = Map.put(board.hands, :north, %{0 => {unit, :nil}})
    board = %{board | hands: hands}
    action = %Board.Action.Place{index: 0, x: 4, y: 4}
    assert {%{grid: grid, hands: hands}, _events} = Board.Action.resolve(action, board, :north)
    assert hands[:north][0] == :nil
    assert grid[{4, 4}] == unit
  end

  test "already_assigned" do
    unit = Unit.new(:north, :test, 3, 3)
    board = %{Board.new() | state: %Placement{}}
    hands = Map.put(board.hands, :north, %{0 => {unit, :nil}})
    board = %{board | hands: hands}
    action = %Board.Action.Place{index: 0, x: 4, y: 4}
    assert {newboard, _events} = Board.Action.resolve(action, board, :north)
    assert {:err, _} = Board.Action.resolve(action, newboard, :north)
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

    action = %Board.Action.Move{from_x: 2, from_y: 4, to_x: 2, to_y: 3}
    assert {newboard, events} = Board.Action.resolve(action, board, :north)
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
    action = %Board.Action.Move{from_x: 4, from_y: 4, to_x: 4, to_y: 3}
    assert {newboard, events} = Board.Action.resolve(action, board, :north)
    assert newboard.grid[{4, 3}] == attacker
    assert Enum.find(events, fn(e) -> e.kind == :unit_died end)
  end

  test "winner winner chicken dinner" do
    attacker = Unit.new(:north, :test, 3, 3)
    defender = Unit.new(:south, :monarch, 1, 1, :nil, %{death: Ability.Concede})
    board =
      Board.new()
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
      Board.new()
      |> Map.put(:state, :battle)
      |> Board.place(unit, {4, 4}) |> elem(1)
      |> Board.place(unit2, {4, 3}) |> elem(1)
    action = %Board.Action.Move{from_x: 4, from_y: 4, to_x: 4, to_y: 3}
    assert {:err, :noselfattack} = Board.Action.resolve(action, board, :north)
  end

  test "push block" do
    unit = Unit.new(:north, :test, 3, 3)
    board =
      Board.new()
      |> Map.put(:state, :battle)
      |> Board.place(unit, {2, 3}) |> elem(1)
      |> fn (b) -> %{b | grid: Map.put(b.grid, {2, 2}, :block)} end.()
    action = %Board.Action.Move{from_x: 2, from_y: 3, to_x: 2, to_y: 2}
    assert {newboard, _events} = Board.Action.resolve(action, board, :north)
    assert newboard.grid[{2, 2}] == unit
    assert newboard.grid[{2, 1}] == :block
  end
end

defmodule YaggTest.Action.Ready do
  use ExUnit.Case

  test "ready" do
    unit = Unit.new(:north, :monarch, 3, 3)
    board = %{Board.new() | state: %Placement{}}
    hands = Map.put(board.hands, :north, %{0 => {unit, {4, 4}}})
    board = %{board | hands: hands}
    action = %Board.Action.Ready{}
    assert {newboard, [event]} = Board.Action.resolve(action, board, :north)
    assert %Placement{ready: :north} == newboard.state
    assert %{player: :north} = event.data
  end

  test "gamestart" do
    unit = Unit.new(:north, :monarch, 3, 3)
    board = %{Board.new() | state: %Placement{ready: :south}}
    hands = Map.put(board.hands, :north, %{0 => {unit, {4, 4}}})
    board = %{board | hands: hands}
    action = %Board.Action.Ready{}
    assert {newboard, _events} = Board.Action.resolve(action, board, :north)
    assert :battle == newboard.state
    assert unit == newboard.grid[{4, 4}]
  end
end

defmodule YaggTest.Action.Ability do
  use ExUnit.Case

  defp set_board(board, []), do: board
  defp set_board(board, [{coord, feature} | features]) do
    grid = Map.put(board.grid, coord, feature)
    set_board(%{board | grid: grid}, features)
  end

  test "selfdestruct" do
    unit = Unit.new(:north, :test, 3, 3, Ability.Selfdestruct)
    unit2 = Unit.new(:north, :test2, 3, 3)
    board =
      Board.new()
      |> Map.put(:state, :battle)
      |> set_board(
        [
          {{4, 4}, unit},
          {{4, 3}, unit2}
        ])
    action = %Board.Action.Ability{name: "selfdestruct", x: 4, y: 4}
    assert {%Board{} = newboard, events} = Board.Action.resolve(action, board, :north)
    assert newboard.grid[{4, 4}] == :nil
    assert newboard.grid[{4, 3}] == :nil
    assert Enum.find(events, fn(e) -> e.kind == :unit_died end)
  end

  test "secondwind" do
    unit = Unit.new(:south, :test, 3, 0, :nil, %{death: Ability.Secondwind})
    unit2 = Unit.new(:north, :test2, 5, 4)
    board =
      Board.new()
      |> Map.put(:state, :battle)
      |> set_board(
        [
          {{4, 4}, unit2},
          {{4, 3}, unit}
        ])
    action = %Board.Action.Move{from_x: 4, from_y: 4, to_x: 4, to_y: 3}
    assert {%Board{} = newboard, events} = Board.Action.resolve(action, board, :north)
    assert Enum.find(events, fn(e) -> e.kind == :unit_died end)
    assert Enum.find(events, fn(e) -> e.kind == :add_to_hand end)
  end
end
