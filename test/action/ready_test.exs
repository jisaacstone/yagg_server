alias Yagg.Unit
alias Yagg.Board
alias Yagg.Board.State.{Placement, Gameover}
alias Yagg.Jobfair
alias Yagg.Board.Configuration
import Helper.Board

defmodule YaggTest.Action.Ready do
  use ExUnit.Case

  def testconfig(), do: %Configuration{
    name: :readyconfig,
    dimensions: {5, 5},
    units: %{north: [], south: []},
    terrain: [],
    initial_module: Board,
  }

  test "ready" do
    unit = Unit.new(:north, :monarch, 3, 3)
    board = new_board(testconfig())
    hands = Map.put(board.hands, :north, %{0 => {unit, {4, 4}}})
    board = %{board | hands: hands}
    action = %Board.Action.Ready{}
    assert {newboard, [event]} = Board.Action.resolve(action, board, :north)
    assert %Placement{ready: :north} == newboard.state
    assert %{player: :north} = event.data
  end

  test "game start" do
    unit = Unit.new(:north, :monarch, 3, 3)
    board = %{new_board(testconfig()) | state: %Placement{ready: :south}}
    hands = Map.put(board.hands, :north, %{0 => {unit, {4, 4}}})
    board = %{board | hands: hands}
    action = %Board.Action.Ready{}
    assert {newboard, _events} = Board.Action.resolve(action, board, :north)
    assert :battle == newboard.state
    assert unit == newboard.grid[{4, 4}]
  end

  test "restart clears board and hand" do
    board = new_board(
      [Unit.Monarch.new(:test), Unit.Spikeder.new(:test), Unit.Sackboom.new(:test)],
      [],
      {5, 5}
    )
    |> Map.put(:state, %Gameover{ready: :south})
    |> put_unit(:north, :spikeder, {3, 3})
    action = %Board.Action.Ready{}
    assert {newboard, _events} = Board.Action.resolve(action, board, :north)
    units = Enum.map(newboard.hands[:north], fn({_, {%{name: n}, _}}) -> n end)
    assert units == [:monarch, :spikeder, :sackboom]
    assert %Placement{} = newboard.state
  end

  test "restart goes to jobfair" do
    board = new_board(Board.Configuration.Alpha)
    |> Map.put(:state, %Gameover{ready: :south})
    action = %Board.Action.Ready{}
    assert {%Jobfair{}, _events} = Board.Action.resolve(action, board, :north)
  end
end

