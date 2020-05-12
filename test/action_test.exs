alias Yagg.Game.{Board, Unit, Player}
alias Yagg.{Action, Game, Event}

defmodule YaggTest.Action do
  use ExUnit.Case

  def setup_game(board, turn \\ :north) do
    players = [Player.new("p1", :north), Player.new("p2", :south)]
    game = %Game{board: board, players: players, state: :battle, turn: turn}
    {game, players}
  end

  test "move unit" do
    unit = Unit.new(:north, :test, 3, 3)
    board = Board.new() |> Board.place(unit, 2, 2) |> elem(1)
    {game, [player, _]} = setup_game(board)
    action = %Action.Move{from_x: 2, from_y: 2, to_x: 2, to_y: 3}
    assert {:notify, events, newgame} = Action.resolve(action, game, player)
    assert newgame.board.grid[{2, 3}] == unit
    assert Enum.find(events, fn(e) -> e.kind == :unit_moved end)
  end

  test "attack" do
    attacker = Unit.new(:north, :test, 3, 3)
    defender = Unit.new(:south, :t2, 1, 1)
    board =
      Board.new()
      |> Board.place(attacker, 0, 0) |> elem(1)
      |> Board.place(defender, 0, 1) |> elem(1)
    {game, [p1, p2]} = setup_game(board)
    action = %Action.Move{from_x: 0, from_y: 0, to_x: 0, to_y: 1}
    assert {:notify, events, newgame} = Action.resolve(action, game, p1)
    assert newgame.board.grid[{0, 1}] == attacker
    assert Enum.find(events, fn(e) -> e.kind == :unit_died end)
  end

  test "notyourturn" do
    unit = Unit.new(:north, :test, 3, 3)
    board = Board.new() |> Board.place(unit, 2, 2) |> elem(1)
    {game, [player, _]} = setup_game(board, :south)
    action = %Action.Move{from_x: 2, from_y: 2, to_x: 2, to_y: 3}
    assert {:err, :notyourturn} = Action.resolve(action, game, player)
  end
 
  test "attackyourself" do
    unit = Unit.new(:north, :test, 3, 3)
    unit2 = Unit.new(:north, :test2, 3, 3)
    board =
      Board.new()
      |> Board.place(unit, 2, 2) |> elem(1)
      |> Board.place(unit2, 2, 3) |> elem(1)
    {game, [player, _]} = setup_game(board, :south)
    action = %Action.Move{from_x: 2, from_y: 2, to_x: 2, to_y: 3}
    assert {:err, :notyourturn} = Action.resolve(action, game, player)
  end
end
