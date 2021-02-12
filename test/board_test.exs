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

  test "immobile draw" do
    board = set_board([
      {{0, 0}, Unit.Flag.new(:north)},
      {{1, 1}, Unit.Burninator.new(:north)},
      {{2, 2}, Unit.Flag.new(:south)}
    ])
    player = Table.Player.new("north")
    table = %Table{id: :test, turn: :north, board: board, history: [], players: [north: player], configuration: %{}, subscribors: []}
    assert {:reply, :ok, table} = Table.handle_call(
      {:board_action, player, %Board.Action.Ability{x: 1, y: 1}},
      self(),
      table
    )
    assert :nil == table.board.grid[{1, 1}]
    assert table.board.state == %Board.State.Gameover{winner: :draw, ready: nil}
  end

  test "immobile lose" do
    board = set_board([
      {{0, 0}, Unit.Flag.new(:north)},
      {{1, 1}, Unit.Burninator.new(:north)},
      {{1, 2}, Unit.Tinker.new(:south)},
      {{2, 2}, Unit.Flag.new(:south)}
    ])
    player = Table.Player.new("north")
    table = %Table{id: :test, turn: :north, board: board, history: [], players: [north: player], configuration: %{}, subscribors: []}
    assert {:reply, :ok, table} = Table.handle_call(
      {:board_action, player, %Board.Action.Ability{x: 1, y: 1}},
      self(),
      table
    )
    assert :nil == table.board.grid[{1, 1}]
    assert table.board.state == %Board.State.Gameover{winner: :south, ready: nil, reason: "cannot move"}
  end

  test "rematch" do
    board = new_board()
    |> Map.put(:state, %Board.State.Gameover{winner: :draw})
    player = Table.Player.new("north")
    table = %Table{id: :test, turn: :north, board: board, history: [], players: [north: player], configuration: %{}, subscribors: []}
    assert {:reply, :ok, table} = Table.handle_call(
      {:board_action, player, %Board.Action.Ready{}},
      self(),
      table
    )
    assert table.board.state == %Board.State.Gameover{winner: :draw, ready: :north}
  end 

  test "concede" do
    board = new_board()
    player = Table.Player.new("north")
    table = %Table{id: :test, turn: :north, board: board, history: [], players: [north: player], configuration: %{}, subscribors: []}
    assert {:reply, :ok, table} = Table.handle_call(
      {:board_action, player, %Board.Action.Concede{}},
      self(),
      table
    )
    assert table.board.state == %Board.State.Gameover{winner: :south, ready: :nil, reason: "conceded"}
  end

  test "endgame" do
    board = %Board{
      configuration: %Board.Configuration{army_size: 12, dimensions: {6, 6}, initial_module: Board, monarch: nil, name: "strat", terrain: [], units: %{}},
      dimensions: {6, 6},
      grid: %{
				{0, 0} => %Unit{attack: 3, defense: 6, name: :major, position: :south, triggers: %{}, visible: MapSet.new([:player])}, 
				{0, 1} => %Unit{attack: 9, defense: 6, name: :marshal, position: :south, triggers: %{}, visible: MapSet.new([:player])}, 
				{0, 4} => %Unit{attack: :immobile, defense: 0, name: :bomb, position: :north, triggers: %{death: Unit.Ability.Poison, move: Unit.Ability.Immobile}, visible: MapSet.new([:player])}, 
				{0, 5} => %Unit{attack: 9, defense: 6, name: :marshal, position: :north, triggers: %{}, visible: MapSet.new([:player])}, 
				{1, 0} => %Unit{attack: 5, defense: 4, name: :sergeant, position: :south, triggers: %{}, visible: MapSet.new([:player])}, 
				{1, 1} => %Unit{attack: 3, defense: 6, name: :major, position: :south, triggers: %{}, visible: MapSet.new([:player])}, 
				{1, 2} => :water, 
				{1, 3} => :water, 
				{2, 0} => %Unit{attack: :immobile, defense: 0, name: :bomb, position: :south, triggers: %{death: Unit.Ability.Poison, move: Unit.Ability.Immobile}, visible: MapSet.new([:player])}, 
				{2, 1} => %Unit{attack: 9, defense: 0, name: :spy, position: :south, triggers: %{}, visible: MapSet.new([:player])}, 
				{2, 4} => %Unit{attack: :immobile, defense: 0, monarch: true, name: :"northern colors", position: :north, triggers: %{death: Unit.Ability.Concede, move: Unit.Ability.Immobile}, visible: MapSet.new([:player])}, 
				{3, 0} => %Unit{attack: 7, defense: 8, name: :general, position: :south, triggers: %{}, visible: MapSet.new([:player])}, 
				{3, 1} => %Unit{attack: :immobile, defense: 0, monarch: true, name: :"southern banner", position: :south, triggers: %{death: Unit.Ability.Concede, move: Unit.Ability.Immobile}, visible: MapSet.new([:player])}, 
				{3, 2} => %Unit{attack: 1, defense: 6, name: :miner, position: :north, triggers: %{attack: Unit.Miner.Defuse}, visible: MapSet.new([:player])}, 
				{3, 4} => %Unit{attack: 9, defense: 0, name: :spy, position: :north, triggers: %{}, visible: MapSet.new([:player])}, 
				{4, 0} => %Unit{attack: 5, defense: 4, name: :sergeant, position: :south, triggers: %{}, visible: MapSet.new([:player])}, 
				{4, 1} => %Unit{attack: :immobile, defense: 0, name: :bomb, position: :south, triggers: %{death: Unit.Ability.Poison, move: Unit.Ability.Immobile}, visible: MapSet.new([:player])}, 
				{4, 2} => :block, 
				{4, 3} => :block, 
				{5, 0} => %Unit{attack: 1, defense: 6, name: :scout, position: :south, triggers: %{attack: Unit.Scout.Spy, move: Unit.Ability.Slide}, visible: MapSet.new([:player])}, 
				{5, 1} => %Unit{attack: 1, defense: 6, name: :miner, position: :south, triggers: %{attack: Unit.Miner.Defuse}, visible: MapSet.new([:player])}, 
				{5, 4} => %Unit{attack: :immobile, defense: 0, name: :bomb, position: :north, triggers: %{death: Unit.Ability.Poison, move: Unit.Ability.Immobile}, visible: MapSet.new([:player])}, 
				{5, 5} => %Unit{attack: 5, defense: 4, name: :sergeant, position: :north, triggers: %{}, visible: MapSet.new([:player])}},
      hands: %{north: %{5 => {%Unit{attack: 1, defense: 6, name: :scout, position: :north, triggers: %{attack: Unit.Scout.Spy, move: Unit.Ability.Slide}, visible: MapSet.new([:player])}, nil}, 8 => {%Unit{attack: 5, defense: 4, name: :sergeant, position: :north, triggers: %{}, visible: MapSet.new([:player])}, nil}, 9 => {%Unit{attack: 7, defense: 8, name: :general, position: :north, triggers: %{}, visible: MapSet.new([:player])}, nil}, 10 => {%Unit{attack: 3, defense: 6, name: :major, position: :north, triggers: %{}, visible: MapSet.new([:player])}, nil}, 11 => {%Unit{attack: 3, defense: 6, name: :major, position: :north, triggers: %{}, visible: MapSet.new([:player])}, nil}}, south: %{}},
      state: :battle
    }
    action = %Board.Action.Move{from_x: 3, from_y: 2, to_x: 3, to_y: 1}
    player = Table.Player.new("north")
    table = %Table{id: :test, turn: :north, board: board, history: [], players: [north: player], configuration: %{}, subscribors: []}
    assert {:reply, :ok, table} = Table.handle_call(
      {:board_action, player, action},
      self(),
      table
    )
    assert table.board.state == %Board.State.Gameover{winner: :north, ready: :nil}
  end
end
