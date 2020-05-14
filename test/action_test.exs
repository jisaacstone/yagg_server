alias Yagg.Game.{Board, Unit, Player}
alias Yagg.{Action, Game, Event}

defmodule YaggTest.Action.Place do
  use ExUnit.Case

  test "place unit" do
    unit = Unit.new(:north, :test, 3, 3)
    board = Board.new()
    hands = Map.put(board.hands, :north, %{0 => {unit, :nil}})
    board = %{board | hands: hands}
    players = [Player.new("p1", :north), Player.new("p2", :south)]
    game = %Game{board: board, players: players, state: :placement, turn: :north, ready: :nil}
    action = %Action.Place{index: 0, x: 4, y: 4}
    assert {:notify, _evt, newgame} = Action.resolve(action, game, hd(players))
    assert newgame.board.hands[:north][0] == {unit, {4, 4}}
  end
end

defmodule YaggTest.Action.Move do
  use ExUnit.Case

  def setup_game(board, turn \\ :north) do
    players = [Player.new("p1", :north), Player.new("p2", :south)]
    game = %Game{board: board, players: players, state: :battle, turn: turn, ready: :nil}
    {game, players}
  end

  test "move unit" do
    unit = Unit.new(:north, :test, 3, 3)
    board = Board.new() |> Board.place(unit, {2, 4}) |> elem(1)
    {game, [player, _]} = setup_game(board)
    action = %Action.Move{from_x: 2, from_y: 4, to_x: 2, to_y: 3}
    assert {:notify, events, newgame} = Action.resolve(action, game, player)
    assert newgame.board.grid[{2, 3}] == unit
    assert Enum.find(events, fn(e) -> e.kind == :unit_moved end)
  end

  test "attack" do
    attacker = Unit.new(:north, :test, 3, 3)
    defender = Unit.new(:south, :t2, 1, 1)
    board =
      Board.new()
      |> Board.place(attacker, {4, 4}) |> elem(1)
      |> fn (b) -> %{b | grid: Map.put(b.grid, {4, 3}, defender)} end.()
    {game, [p1, p2]} = setup_game(board)
    action = %Action.Move{from_x: 4, from_y: 4, to_x: 4, to_y: 3}
    assert {:notify, events, newgame} = Action.resolve(action, game, p1)
    assert newgame.board.grid[{4, 3}] == attacker
    assert Enum.find(events, fn(e) -> e.kind == :unit_died end)
  end

  test "notyourturn" do
    unit = Unit.new(:north, :test, 3, 3)
    board = Board.new() |> Board.place(unit, {2, 4}) |> elem(1)
    {game, [player, _]} = setup_game(board, :south)
    action = %Action.Move{from_x: 2, from_y: 4, to_x: 2, to_y: 3}
    assert {:err, :notyourturn} = Action.resolve(action, game, player)
  end
 
  test "attackyourself" do
    unit = Unit.new(:north, :test, 3, 3)
    unit2 = Unit.new(:north, :test2, 3, 3)
    board =
      Board.new()
      |> Board.place(unit, {4, 4}) |> elem(1)
      |> Board.place(unit, {4, 3}) |> elem(1)
    {game, [player, _]} = setup_game(board)
    action = %Action.Move{from_x: 4, from_y: 4, to_x: 4, to_y: 3}
    assert {:err, :noselfattack} = Action.resolve(action, game, player)
  end
end
