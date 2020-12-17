alias Yagg.Unit
alias Yagg.Board
alias Yagg.Board.Action.Ability
import Helper.Board

defmodule YaggTest.Action.Ability do
  use ExUnit.Case

  test "selfdestruct" do
    unit = Unit.Explody.new(:north)
    unit2 = Unit.new(:north, :test2, 3, 3)
    unit3 = Unit.new(:south, :test3, 7, 3)
    board = set_board(
        [
          {{4, 4}, unit},
          {{4, 3}, unit2},
          {{3, 4}, unit3}
        ])
    action = %Board.Action.Move{from_x: 3, from_y: 4, to_x: 4, to_y: 4}
    assert {%Board{} = newboard, events} = Board.Action.resolve(action, board, :south)
    assert newboard.grid[{4, 4}] == :nil
    assert newboard.grid[{4, 3}] == :nil
    assert Enum.find(events, fn(e) -> e.kind == :unit_died end)
  end

  test "secondwind" do
    unit = Unit.new(:south, :test, 3, 0, :nil, %{death: Ability.Secondwind})
    unit2 = Unit.new(:north, :test2, 5, 4)
    board = set_board(
        [
          {{4, 4}, unit2},
          {{4, 3}, unit}
        ])
    action = %Board.Action.Move{from_x: 4, from_y: 4, to_x: 4, to_y: 3}
    assert {%Board{} = newboard, events} = Board.Action.resolve(action, board, :north)
    assert Enum.find(events, fn(e) -> e.kind == :unit_died end)
    assert Enum.find(events, fn(e) -> e.kind == :add_to_hand end)
  end

  test "tactician" do
    unitM = Unit.Tactician.new(:south)
    unitF = Unit.new(:south, :unit, 3, 2)
    unitE = Unit.new(:north, :enemy, 5, 4)
    board = set_board(
        [
          {{2, 2}, unitM},
          {{3, 2}, unitF},
          {{1, 2}, unitE},
        ])
    action = %Board.Action.Move{from_x: 2, from_y: 2, to_x: 2, to_y: 3}
    assert {%Board{} = newboard, events} = Board.Action.resolve(action, board, :south)
    assert newboard.grid[{2, 2}] == :nil
    assert newboard.grid[{3, 2}] == :nil
    assert newboard.grid[{1, 2}] == unitE
    assert newboard.grid[{3, 3}] == unitF
  end

  test "push manuver" do
    unitM = Unit.Tactician.new(:south)
    unitP = Unit.Pushie.new(:south)
    board = set_board(
        [
          {{2, 3}, unitP},
          {{1, 3}, unitM},
          {{2, 2}, :block},
        ])
    action = %Board.Action.Ability{x: 2, y: 3}
    assert {%Board{} = newboard, events} = Board.Action.resolve(action, board, :south)
    assert newboard.grid[{2, 3}] == :nil
    assert newboard.grid[{1, 3}].name == unitP.name
    assert newboard.grid[{0, 3}].name == unitM.name
    assert newboard.grid[{2, 1}] == :block
  end

  test "spikeder slide" do
    spikeder = Unit.Spikeder.new(:south)
    enemy = Unit.Sparky.new(:north)
    board = set_board(
        [
          {{3, 0}, spikeder},
          {{3, 4}, enemy}
        ])
    action = %Board.Action.Move{from_x: 3, from_y: 0, to_x: 3, to_y: 1}
    assert {%Board{} = newboard, _events} = Board.Action.resolve(action, board, :south)
    assert newboard.grid[{3, 0}] == :nil
    assert newboard.grid[{3, 4}] == spikeder
  end

  test "busybody" do
    busybody = Unit.Busybody.new(:south)
    other = Unit.Pushie.new(:south)
    board = set_board([
      {{0, 2}, busybody},
      {{1, 2}, :water},
      {{0, 1}, other},
    ])
    action = %Board.Action.Ability{x: 0, y: 2}
    assert {%Board{} = newboard, events} = Board.Action.resolve(action, board, :south)
    assert newboard.grid[{0, 2}].name == busybody.name
    assert newboard.grid[{0, 1}] == :water
    assert Enum.find(events, fn(e) -> e.kind == :unit_died end)
    assert Enum.find(events, fn(e) -> e.kind == :multi end)
  end

  test "illegal square" do
    grid = %{
      {0, 1} => %Unit{ability: Board.Action.Ability.Upgrade, attack: 3, defense: 2, name: :electromouse, position: :south, triggers: %{}},
      {0, 2} => %Unit{ability: nil, attack: 5, defense: 4, name: :mediacreep, position: :north, triggers: %{move: Unit.Mediacreep.Duplicate}},
      {1, 0} => :water,
      {1, 1} => %Unit{ability: Unit.Busybody.Spin, attack: 3, defense: 6, name: :busybody, position: :south, triggers: %{}},
      {1, 2} => %Unit{ability: nil, attack: 1, defense: 8, name: :tim, position: :south, triggers: %{}},
      {3, 0} => %Unit{ability: Board.Action.Ability.Concede, attack: 1, defense: 0, name: :monarch, position: :south, triggers: %{death: Board.Action.Ability.Concede}},
      {3, 3} => %Unit{ability: nil, attack: 9, defense: 2, name: :bezerker, position: :north, triggers: %{}},
      {3, 4} => %Unit{ability: Board.Action.Ability.Concede, attack: 1, defense: 0, name: :monarch, position: :north, triggers: %{death: Board.Action.Ability.Concede}},
      {4, 3} => :water
    }
    action = %Board.Action.Move{from_x: 0, from_y: 2, to_x: 0, to_y: 3}
    board = %Board{grid: grid, state: :battle, hands: [], dimensions: {5, 5}, configuration: Board.Configuration.Alpha}
    assert {%Board{} = newboard, events} = Board.Action.resolve(action, board, :north)
  end

  test "timeout" do
    grid = %{
      {0, 2} => Unit.Dogatron.new(:south),
      {1, 2} => Unit.Explody.new(:north),
      {1, 3} => %Unit{ability: Unit.Busybody.Spin, attack: 3, defense: 6, name: :busybody, position: :north, triggers: %{}},
      {2, 0} => %Unit{ability: Board.Action.Ability.Concede, attack: 1, defense: 0, name: :monarch, position: :south, triggers: %{death: Board.Action.Ability.Concede}},
      {4, 4} => %Unit{ability: Board.Action.Ability.Concede, attack: 1, defense: 0, name: :monarch, position: :north, triggers: %{death: Board.Action.Ability.Concede}},
      {4, 3} => :water
    }
    action = %Board.Action.Move{from_x: 0, from_y: 2, to_x: 1, to_y: 2}
    board = %Board{grid: grid, state: :battle, hands: %{north: %{}, south: %{}}, dimensions: {5, 5}, configuration: Board.Configuration.Alpha}
    assert {%Board{} = newboard, events} = Board.Action.resolve(action, board, :south)
  end

  test "spark" do
    sparkle = %{Unit.Maycorn.new(:south) | ability: Unit.Maycorn.Spark.Front}
    tink = Unit.Tinker.new(:north)
    board = set_board([
      {{4, 2}, sparkle},
      {{4, 4}, tink}
    ])
    action = %Board.Action.Ability{x: 4, y: 2}
    assert {%Board{} = newboard, _events} = Board.Action.resolve(action, board, :south)
    assert newboard.grid[{4, 4}] == :nil
  end

  test "spindeath monarch" do
    board = set_board([
      {{2, 6}, Unit.Busybody.new(:north)},
      {{3, 6}, Unit.Monarch.new(:north)},
    ])
    action = %Board.Action.Ability{x: 2, y: 6}
    assert {%Board{} = newboard, events} = Board.Action.resolve(action, board, :north)
    assert newboard.grid[{3, 6}] == :nil
    assert Enum.any?(events, fn(e) -> e.kind == :unit_died end)
    assert Enum.any?(events, fn(e) -> e.kind == :gameover end)
  end

  test "catmover jump" do
    board = set_board([
      {{1, 2}, Unit.Catmover.new(:south)},
      {{2, 2}, Unit.Tinker.new(:north)}
    ])
    action = %Board.Action.Move{from_x: 1, from_y: 2, to_x: 2, to_y: 2}
    assert {%Board{} = newboard, events} = Board.Action.resolve(action, board, :south)
    assert newboard.grid[{2, 2}] == :nil
    assert %Unit{name: :catmover} = newboard.grid[{3, 2}]
    assert event = Enum.find(events, fn(e) -> e.kind == :thing_moved end)
    assert %{from: {1, 2}, to: {3, 2}} = event.data
  end

  test "jump oob" do
    board = set_board([
      {{3, 2}, Unit.Catmover.new(:south)},
      {{4, 2}, Unit.Tinker.new(:north)}
    ])
    action = %Board.Action.Move{from_x: 3, from_y: 2, to_x: 4, to_y: 2}
    assert {%Board{} = newboard, events} = Board.Action.resolve(action, board, :south)
    assert event = Enum.find(events, fn(e) -> e.kind == :unit_died end)
    assert %{name: :tinker} = newboard.grid[{4, 2}]
  end

  test "antente becomes visible" do
    board = set_board([
      {{1, 2}, Unit.Antente.new(:south)},
      {{2, 2}, Unit.Tinker.new(:north)}
    ])

    action = %Board.Action.Move{from_x: 1, from_y: 2, to_x: 2, to_y: 2}
    assert {%Board{} = newboard, events} = Board.Action.resolve(action, board, :south)
    assert %{name: :antente, ability: Unit.Antente.Invisible} = newboard.grid[{2, 2}]
    plc_idx = Enum.find_index(events, fn(e) -> e.kind == :unit_placed end)
    mv_idx = Enum.find_index(events, fn(e) -> e.kind == :thing_moved end)
    assert plc_idx < mv_idx
    assert %{stream: :global} = Enum.at(events, mv_idx)

    action = %Board.Action.Ability{x: 2, y: 2}
    assert {board, events} = Board.Action.resolve(action, newboard, :south)
    assert Enum.any?(events, fn(e) -> e.kind == :thing_gone end)
    assert %{ability: :nil} = board.grid[{2, 2}]
  end

  test "strange move" do
    board = set_board([
      {{3, 1}, %Unit{ability: nil, attack: 9, defense: 2, name: :bezerker, position: :south, triggers: %{}, visible: MapSet.new([:player])}}, 
      {{3, 2}, nil} 
    ])
    action = %Board.Action.Move{from_x: 3, from_y: 1, to_x: 3, to_y: 2}
    assert {%Board{} = newboard, _events} = Board.Action.resolve(action, board, :south)
    assert %{name: :bezerker} = newboard.grid[{3, 2}]
  end

  test "electromousetrap" do
    board = set_board([
      {{3, 2}, Unit.Tinker.new(:north)},
      {{4, 2}, Unit.Electromouse.new(:south)}
    ])
    action = %Board.Action.Ability{x: 4, y: 2}
    assert {%Board{} = board, _events} = Board.Action.resolve(action, board, :south)
    assert %{name: :"electromouse trap", triggers: %{move: Unit.Electromouse.Settrap}} = board.grid[{4, 2}]
    action = %Board.Action.Move{from_x: 4, from_y: 2, to_x: 4, to_y: 3}
    assert {%Board{} = board, events} = Board.Action.resolve(action, board, :south)
    assert %{name: :electromouse, triggers: %{}} = board.grid[{4, 3}]
    assert Enum.find(events, fn(e) -> e.kind == :new_unit end)
    assert %{name: :electromousetrap} = board.grid[{4, 2}]
    action = %Board.Action.Move{from_x: 3, from_y: 2, to_x: 4, to_y: 2}
    assert {%Board{} = board, _events} = Board.Action.resolve(action, board, :north)
    assert %{name: :tinker, position: :south} = board.grid[{4, 2}]
  end

  test "electromousetrap monarch" do
    board = set_board([
      {{3, 2}, Unit.Monarch.new(:north)},
      {{4, 2}, Unit.Electromouse.new(:south)}
    ])
    action = %Board.Action.Ability{x: 4, y: 2}
    assert {%Board{} = board, _events} = Board.Action.resolve(action, board, :south)
    assert %{name: :"electromouse trap", triggers: %{move: Unit.Electromouse.Settrap}} = board.grid[{4, 2}]
    action = %Board.Action.Move{from_x: 3, from_y: 2, to_x: 4, to_y: 2}
    assert {%Board{} = board, events} = Board.Action.resolve(action, board, :north)
    assert Enum.find(events, fn(e) -> e.kind == :gameover end)
  end

  test "electromouse trap" do
    board = set_board([
      {{2, 2}, %Unit{ability: nil, attack: 9, defense: 2, name: :bezerker, position: :south, triggers: %{}, visible: MapSet.new([:player])}},
      {{2, 3}, %Unit{ability: nil, attack: 3, defense: 4, name: :"electromouse trap", position: :north, triggers: %{death: Unit.Electromousetrap.Trap, move: Unit.Electromouse.Settrap}, visible: MapSet.new([:player])}}
    ])
    action = %Board.Action.Move{from_x: 2, from_y: 2, to_x: 2, to_y: 3}
    assert {%Board{} = newboard, _events} = Board.Action.resolve(action, board, :south)
    assert %{name: :bezerker, position: :north} = newboard.grid[{2, 3}]
  end

  test "electromousetrap attack" do
    board = set_board([
      {{3, 2}, Unit.Sackboom.new(:north)},
      {{4, 2}, Unit.Electromouse.new(:south)}
    ])
    action = %Board.Action.Ability{x: 4, y: 2}
    assert {%Board{} = board, _events} = Board.Action.resolve(action, board, :south)
    assert %{name: :"electromouse trap", triggers: %{move: Unit.Electromouse.Settrap}} = board.grid[{4, 2}]
    action = %Board.Action.Move{from_x: 4, from_y: 2, to_x: 3, to_y: 2}
    assert {%Board{} = board, _events} = Board.Action.resolve(action, board, :south)
    assert %{name: :electromousetrap, triggers: %{death: Unit.Electromousetrap.Trap}} = board.grid[{4, 2}]
    assert %{name: :sackboom} = board.grid[{3, 2}]
  end
end
