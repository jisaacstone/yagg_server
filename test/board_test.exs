alias Yagg.Unit
alias Yagg.Table
alias Yagg.Board
import Helper.Board

defmodule YaggTest.Board do
  use ExUnit.Case

  test "draw" do
    board = new_board(
      [Unit.Monarch.new(:test), Unit.Burninator.new(:test), Unit.Sackboom.new(:test)],
      [],
      {5, 5}
    )
    |> Map.put(:state, :battle)
    |> put_unit(:north, :burninator, {3, 3})
    |> put_unit(:north, :monarch, {2, 3})
    |> put_unit(:south, :monarch, {1, 3})
    player = Table.Player.new("north")
    table = %Table{id: :test, turn: :north, board: board, history: [], players: [north: player], configuration: %{}, subscribors: []}
    assert {:reply, :ok, table} = Table.handle_call(
      {:board_action, player, %Board.Action.Ability{x: 3, y: 3}},
      self(),
      table
    )
    assert table.board.state == %Board.State.Gameover{winner: :draw, ready: nil}
  end
end
