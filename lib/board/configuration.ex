alias Yagg.Table.Player
alias Yagg.Unit
alias Yagg.Board.Action.Ability
alias Yagg.Board

defmodule Yagg.Board.Configuration do
  @callback starting_units(Player.position()) :: [Unit.t, ...]
  @callback terrain() :: [{Board.Grid.coord(), Board.Grid.terrain()}]

  def all() do
    %{
      "random" => Board.Configuration.Random,
      "alpha" => Board.Configuration.Alpha,
      "beta" => Board.Configuration.Chain,
    }
  end
end

defmodule Board.Configuration.Random do
  @behaviour Board.Configuration
  @impl Board.Configuration
  def starting_units(position) do
    units = Enum.shuffle([
      Unit.Tactician.new(position),
      Unit.new(position, :bezerker, 9, 2),
      Unit.new(position, :chopper, 7, 4),
      Unit.new(position, :tim, 1, 8),
      Unit.new(position, :rollander, 1, 6, :nil, %{death: Ability.Secondwind}),
      Unit.Explody.new(position),
      Unit.Pushie.new(position),
      Unit.new(position, :poisonblade, 3, 4, :nil, %{death: Ability.Poisonblade}),
      Unit.new(position, :rowburninator, 1, 2, Ability.Rowburn),
      Unit.Tinker.new(position),
      Unit.new(position, :electromouse, 3, 2, Ability.Upgrade),
      Unit.Mediacreep.new(position),
      Unit.new(position, :sparky, 1, 0, Ability.Copyleft),
      Unit.new(position, :dogatron, 1, 0, :nil, %{death: Ability.Upgrade}),
      Unit.Maycorn.new(position),
      Unit.Spikeder.new(position),
      Unit.Busybody.new(position),
    ]) |> Enum.take(7)
    [Unit.new(position, :monarch, 1, 0, Ability.Concede, %{death: Ability.Concede}) | units]
  end

  @impl Board.Configuration
  def terrain() do
    gen_terrain(
      %{{Enum.random(0..4), Enum.random(0..4)} => Enum.random([:water, :block])},
      Enum.random(0..3)
    )
  end

  def gen_terrain(terrain, 0) do
    Map.to_list(terrain)
  end
  def gen_terrain(terrain, n) do
    Map.put(
      terrain,
      {Enum.random([0,1,1,2,3,3,4]), Enum.random([0,1,1,2,2,2,2,3,3,4])},
      Enum.random([:water, :block])
    ) |> gen_terrain(n - 1)
  end
end

defmodule Board.Configuration.Alpha do
  @behaviour Board.Configuration

  @impl Board.Configuration
  def starting_units(position) do
    Enum.shuffle([
      Unit.new(position, :monarch, 1, 0, Ability.Concede, %{death: Ability.Concede}),
      Unit.Tactician.new(position),
      Unit.new(position, :bezerker, 7, 2),
      Unit.new(position, :fullarmorcoward, 1, 6, :nil, %{death: Ability.Secondwind}),
      Unit.Explody.new(position),
      Unit.Pushie.new(position),
      Unit.new(position, :poisonblade, 3, 4, :nil, %{death: Ability.Poisonblade}),
      Unit.new(position, :rowburninator, 3, 2, Ability.Rowburn),
    ])
  end

  @impl Board.Configuration
  def terrain() do
    [
      {{1, 2}, :block},
      {{4, 2}, :water},
    ]
  end
end

defmodule Board.Configuration.Chain do
  @behaviour Board.Configuration
  @doc """
  Returns ten standard units in a random order
  """

  @impl Board.Configuration
  def starting_units(position) do
    Enum.shuffle([
      Unit.new(position, :monarch, 1, 0, Ability.Concede, %{death: Ability.Concede}),
      Unit.new(position, :mosh, 3, 4, Ability.Push),
      Unit.new(position, :bezerker, 7, 2),
      Unit.new(position, :dogatron, 3, 4, Ability.Secondwind),
      Unit.new(position, :explody, 3, 2, :nil, %{death: Ability.Selfdestruct}),
      Unit.new(position, :colburninator, 1, 2, Ability.Colburn),
      Unit.new(position, :poisonblade, 3, 4, :nil, %{death: Ability.Poisonblade}),
      Unit.new(position, :rowburninator, 3, 2, Ability.Rowburn),
    ])
  end

  @impl Board.Configuration
  def terrain() do
    [
      {{0, 0}, :water},
      {{4, 4}, :water},
      {{0, 4}, :water},
      {{4, 0}, :water},
      {{2, 2}, :block},
    ]
  end
end
