alias Yagg.Table
alias Yagg.Board
alias Yagg.Jobfair
alias Yagg.Unit
alias Yagg.Table.Action

defmodule Board.Configuration.AlphaTest do
  @behaviour Board.Configuration

  @impl Board.Configuration
  def starting_units(position) do
    [
      Unit.Monarch.new(position),
      Unit.Tactician.new(position),
      Unit.Busybody.new(position),
      Unit.Explody.new(position),
      Unit.Pushie.new(position),
      Unit.Mediacreep.new(position),
      Unit.Sackboom.new(position),
      Unit.Spikeder.new(position),
    ]
  end

  @impl Board.Configuration
  def terrain(_) do
    [
      {{1, 2}, :block},
      {{4, 2}, :water},
    ]
  end

  @impl Board.Configuration
  def meta() do
    %{
      dimensions: {5, 5},
      initial_module: Jobfair,
      min: 2,
      max: 4
    }
  end

end

defmodule YaggTest.Jobfair do
  use ExUnit.Case

  def start(conf \\ Board.Configuration.AlphaTest) do
    {:ok, pid} = Table.new(conf)
    table_id = Table.pid_to_id(pid)
    :ok = Table.table_action(table_id, "p1", %Action.Join{player: "p1"})
    :ok = Table.table_action(table_id, "p2", %Action.Join{player: "p2"})
    {:ok, table} = Table.get_state(table_id)
    {table_id, table}
  end

  test "recruit" do
    {table_id, table} = start()
    p1 = hd(table.players)
    choices = [0,2,4]
    action = %Action.Recruit{units: choices}
    :ok = Table.table_action(table_id, p1.name, action)
    {:ok, table} = Table.get_state(table_id)
    fair = Map.get(table.board, p1.position)
    assert fair.ready == :true
  end

  test "gamestart" do
    {table_id, table} = start()
    [p1, p2] = table.players
    u1 = Map.get(table.board, p1.position).choices
    u2 = Map.get(table.board, p2.position).choices
    {c1, c2} = {[0,2,4], [1,3,4]}
    :ok = Table.table_action(table_id, p1.name, %Action.Recruit{units: c1})
    :ok = Table.table_action(table_id, p2.name, %Action.Recruit{units: c2})
    {:ok, table} = Table.get_state(table_id)
    assert %Board{} = table.board
    h1 = table.board.hands[p1.position]
    hu1 = Enum.map(h1, fn({_, {v, _}}) -> v end) |> MapSet.new()
    ou1 = [Unit.Monarch.new(p1.position), u1[0], u1[2], u1[4]] |> MapSet.new()
    assert hu1 == ou1
    h2 = table.board.hands[p2.position]
    hu2 = Enum.map(h2, fn({_, {v, _}}) -> v end) |> MapSet.new()
    ou2 = [Unit.Monarch.new(p2.position), u2[1], u2[3], u2[4]] |> MapSet.new()
    assert hu2 == ou2
  end

  defmodule IndiciesTestConfig do
    defmodule Initial do
      def new(_config) do
        %Yagg.Jobfair{max: 8, min: 6,
          north: %{choices: %{
            0 => %Yagg.Unit{ability: nil, attack: 5, defense: 4, name: :tactician, position: :north, triggers: %{move: Yagg.Unit.Tactician.Manuver}}, 
            1 => %Yagg.Unit{ability: Yagg.Unit.Busybody.Spin, attack: 3, defense: 6, name: :busybody, position: :north, triggers: %{}}, 
            2 => %Yagg.Unit{ability: nil, attack: 3, defense: 2, name: :explody, position: :north, triggers: %{death: Yagg.Unit.Explody.Selfdestruct}}, 
            3 => %Yagg.Unit{ability: Yagg.Board.Action.Ability.Push, attack: 3, defense: 0, name: :pushie, position: :north, triggers: %{}}, 
            4 => %Yagg.Unit{ability: nil, attack: 5, defense: 4, name: :mediacreep, position: :north, triggers: %{move: Yagg.Unit.Mediacreep.Duplicate}}, 
            5 => %Yagg.Unit{ability: nil, attack: 3, defense: 6, name: :sackboom, position: :north, triggers: %{move: Yagg.Unit.Sackboom.Move.Zero}}, 
            6 => %Yagg.Unit{ability: nil, attack: 3, defense: 2, name: :spikeder, position: :north, triggers: %{death: Yagg.Board.Action.Ability.Poisonblade, move: Yagg.Unit.Spikeder.Slide}}, 
            7 => %Yagg.Unit{ability: Yagg.Board.Action.Ability.Copyleft, attack: 1, defense: 0, name: :sparky, position: :north, triggers: %{}}, 
            8 => %Yagg.Unit{ability: nil, attack: 1, defense: 0, name: :dogatron, position: :north, triggers: %{death: Yagg.Board.Action.Ability.Upgrade}}, 
            9 => %Yagg.Unit{ability: nil, attack: 3, defense: 4, name: :poisonblade, position: :north, triggers: %{death: Yagg.Board.Action.Ability.Poisonblade}},
            10 => %Yagg.Unit{ability: Yagg.Board.Action.Ability.Rowburn, attack: 3, defense: 2, name: :rowburninator, position: :north, triggers: %{}},
            11 => %Yagg.Unit{ability: nil, attack: 9, defense: 2, name: :bezerker, position: :north, triggers: %{}},
            12 => %Yagg.Unit{ability: Yagg.Board.Action.Ability.Copyleft, attack: 1, defense: 0, name: :sparky, position: :north, triggers: %{}},
            13 => %Yagg.Unit{ability: nil, attack: 1, defense: 0, name: :dogatron, position: :north, triggers: %{death: Yagg.Board.Action.Ability.Upgrade}},
            14 => %Yagg.Unit{ability: nil, attack: 1, defense: 8, name: :tim, position: :north, triggers: %{}},
            15 => %Yagg.Unit{ability: nil, attack: 1, defense: 6, name: :rollander, position: :north, triggers: %{death: Yagg.Board.Action.Ability.Secondwind}}},
            chosen: [], ready: false},
          south: %{choices: %{
            0 => %Yagg.Unit{ability: nil, attack: 5, defense: 4, name: :tactician, position: :south, triggers: %{move: Yagg.Unit.Tactician.Manuver}}, 
            1 => %Yagg.Unit{ability: Yagg.Unit.Busybody.Spin, attack: 3, defense: 6, name: :busybody, position: :south, triggers: %{}}, 
            2 => %Yagg.Unit{ability: nil, attack: 3, defense: 2, name: :explody, position: :south, triggers: %{death: Yagg.Unit.Explody.Selfdestruct}}, 
            3 => %Yagg.Unit{ability: Yagg.Board.Action.Ability.Push, attack: 3, defense: 0, name: :pushie, position: :south, triggers: %{}}, 
            4 => %Yagg.Unit{ability: nil, attack: 5, defense: 4, name: :mediacreep, position: :south, triggers: %{move: Yagg.Unit.Mediacreep.Duplicate}}, 
            5 => %Yagg.Unit{ability: nil, attack: 3, defense: 6, name: :sackboom, position: :south, triggers: %{move: Yagg.Unit.Sackboom.Move.Zero}}, 
            6 => %Yagg.Unit{ability: nil, attack: 3, defense: 2, name: :spikeder, position: :south, triggers: %{death: Yagg.Board.Action.Ability.Poisonblade, move: Yagg.Unit.Spikeder.Slide}}, 
            7 => %Yagg.Unit{ability: Yagg.Board.Action.Ability.Copyleft, attack: 1, defense: 0, name: :sparky, position: :south, triggers: %{}}, 
            8 => %Yagg.Unit{ability: nil, attack: 1, defense: 0, name: :dogatron, position: :south, triggers: %{death: Yagg.Board.Action.Ability.Upgrade}}, 
            9 => %Yagg.Unit{ability: nil, attack: 3, defense: 4, name: :poisonblade, position: :south, triggers: %{death: Yagg.Board.Action.Ability.Poisonblade}},
            10 => %Yagg.Unit{ability: Yagg.Board.Action.Ability.Rowburn, attack: 3, defense: 2, name: :rowburninator, position: :south, triggers: %{}},
            11 => %Yagg.Unit{ability: nil, attack: 9, defense: 2, name: :bezerker, position: :south, triggers: %{}},
            12 => %Yagg.Unit{ability: Yagg.Board.Action.Ability.Copyleft, attack: 1, defense: 0, name: :sparky, position: :south, triggers: %{}},
            13 => %Yagg.Unit{ability: nil, attack: 1, defense: 0, name: :dogatron, position: :south, triggers: %{death: Yagg.Board.Action.Ability.Upgrade}},
            14 => %Yagg.Unit{ability: nil, attack: 1, defense: 8, name: :tim, position: :south, triggers: %{}},
            15 => %Yagg.Unit{ability: nil, attack: 1, defense: 6, name: :rollander, position: :south, triggers: %{death: Yagg.Board.Action.Ability.Secondwind}}},
            chosen: [13, 8, 5, 9, 10, 6, 2, 3], ready: true}
        }
      end
    end
    def meta() do
      %{initial_module: Initial, dimensions: {7, 7}}
    end
    def terrain(_), do: []
  end
  test 'indices' do
    {table_id, table} = start(IndiciesTestConfig)
    north = Enum.find(table.players, fn(p) -> p.position == :north end)
    action = %Action.Recruit{units: [10, 15, 11, 7, 6, 5, 1, 0]}
    :ok = Table.table_action(table_id, north.name, action)
    {:ok, table} = Table.get_state(table_id)
    assert %Board{} = table.board
  end
end
