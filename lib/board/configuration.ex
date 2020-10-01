alias Yagg.Table.Player
alias Yagg.Unit
alias Yagg.Board.Action.Ability
alias Yagg.Board
alias Yagg.Jobfair

defmodule Yagg.Board.Configuration do
  @callback starting_units(Player.position()) :: [Unit.t, ...]
  @callback terrain(Board.t) :: [{Board.Grid.coord(), Board.Grid.terrain()}]
  @callback meta() :: %{
    required(:dimensions) => {4..8, 4..8},
    optional(:initial_module) => Jobfair | Board,
    optional(:max) => non_neg_integer,
    optional(:min) => non_neg_integer,
  }

  def dimensions(configuration) do
    configuration.meta().dimensions
  end

  def initial_board(configuration) do
    mod = Map.get(configuration.meta(), :initial_module, Board)
    mod.new(configuration)
  end

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
      Unit.Sackboom.new(position),
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
    ]) |> Enum.take(10)
    [Unit.Monarch.new(position) | units]
  end

  @impl Board.Configuration
  def meta do
    size = Enum.random(4..7)
    %{
      dimensions: {size, size},
    }
  end

  @impl Board.Configuration
  def terrain(%{dimensions: dim}) do
    gen_terrain(
      %{},
      dim,
      Enum.random(0..elem(dim, 0)) + 1
    )
  end

  def gen_terrain(terrain, _, 0) do
    Map.to_list(terrain)
  end
  def gen_terrain(terrain, {width, height}, n) do
    Map.put(
      terrain,
      {Enum.random(0..(width-1)), Enum.random(0..(height-1))},
      Enum.random([:water, :block])
    ) |> gen_terrain({width, height}, n - 1)
  end
end

defmodule Board.Configuration.Alpha do
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
      Unit.new(position, :sparky, 1, 0, Ability.Copyleft),
      Unit.new(position, :dogatron, 1, 0, :nil, %{death: Ability.Upgrade}),
      Unit.new(position, :poisonblade, 3, 4, :nil, %{death: Ability.Poisonblade}),
      Unit.new(position, :rowburninator, 3, 2, Ability.Rowburn),
      Unit.new(position, :bezerker, 9, 2),
      Unit.new(position, :sparky, 1, 0, Ability.Copyleft),
      Unit.new(position, :dogatron, 1, 0, :nil, %{death: Ability.Upgrade}),
      Unit.new(position, :tim, 1, 8),
      Unit.new(position, :rollander, 1, 6, :nil, %{death: Ability.Secondwind}),
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
      min: 6,
      max: 8
    }
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
      Unit.Monarch.new(position),
      Unit.Catmover.new(position),
      Unit.new(position, :bezerker, 7, 2),
      Unit.new(position, :dogatron, 3, 4, Ability.Secondwind),
      Unit.Explody.new(position),
      Unit.Tactician.new(position),
      Unit.Sackboom.new(position),
      Unit.new(position, :poisonblade, 3, 4, :nil, %{death: Ability.Poisonblade}),
      Unit.new(position, :rowburninator, 3, 2, Ability.Rowburn),
    ])
  end

  @impl Board.Configuration
  def terrain(_) do
    [
      {{0, 0}, :water},
      {{6, 6}, :water},
      {{0, 6}, :water},
      {{6, 0}, :water},
      {{2, 2}, :block},
      {{4, 4}, :block},
    ]
  end

  @impl Board.Configuration
  def meta do
    %{
      dimensions: {7, 7}
    }
  end
end
