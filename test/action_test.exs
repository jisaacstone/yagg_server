alias Yagg.Game.{Board, Unit, Player}
alias Yagg.{Action, Game, Event}

defmodule YaggTest.Action do
  use ExUnit.Case

  test "move unit" do
    player = Player.new("player1", :north)
    unit = Unit.new(:north, :test, 3, 3, "north-test")
    board = Board.new() |> Board.place(unit, 2, 2) |> elem(1)
    game = %Game{board: board, players: [player], state: :battle}
    action = %Action.Move{id: unit.id, to_x: 2, to_y: 3}
    assert {:notify, events, newgame} = Action.resolve(action, game, player)
    assert newgame.board.features[{2, 3}] == unit
    assert [%Event{kind: :unit_moved}] = events
  end

  test "attack" do
    [p1, p2] = [Player.new("p1", :north), Player.new("p2", :south)]
    attacker = Unit.new(:north, :test, 3, 3, "north-test")
    defender = Unit.new(:south, :t2, 1, 1, "south-test")
    board =
      Board.new()
      |> Board.place(attacker, 0, 0) |> elem(1)
      |> Board.place(defender, 0, 1) |> elem(1)
    game = %Game{board: board, players: [p1, p2], state: :battle}
    action = %Action.Move{id: attacker.id, to_x: 0, to_y: 1}
    assert {:notify, events, newgame} = Action.resolve(action, game, p1)
    assert newgame.board.features[{0, 1}] == attacker
    assert Enum.find(events, fn(e) -> e.kind == :unit_died end)
  end
end
