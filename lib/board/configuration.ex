alias Yagg.Unit
alias Yagg.Board.Action.Ability
alias Yagg.Board
alias Yagg.Jobfair
alias Yagg.Event

defmodule Yagg.Board.Configuration do
  alias __MODULE__

  @enforce_keys [:dimensions, :initial_module, :units, :terrain]
  @derive {Poison.Encoder, only: [:dimensions, :initial_module]}
  defstruct [:army_size | @enforce_keys]

  @type t :: %Configuration{
    dimensions: {5..9, 5..9},
    initial_module: Jobfair | Board,
    units: any,
    terrain: any,
  }

  @callback new() :: t

  def init(%Configuration{initial_module: mod} = config) do
    mod.new(config)
  end

  @spec setup(t) :: {Jobfair.t | Board.t, [Event.t]}
  def setup(%Configuration{initial_module: mod} = config) do
    mod.new(config) |> mod.setup()
  end

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
      "smallz" => Board.Configuration.Alpha,
      "bigga" => Board.Configuration.Chain,
    }
  end
end

defmodule Board.Configuration.Random do
  @behaviour Board.Configuration
  @impl Board.Configuration
  def new() do
    nor_units = ten_random_units(:north)
    sou_units = Enum.map(nor_units, fn(u) -> %{u | position: :south} end)
    size = Enum.random(5..8)
    dimensions = {size, size}
    terrain = random_terrain(dimensions)
    %Board.Configuration{
      dimensions: dimensions,
      terrain: terrain,
      units: %{north: nor_units, south: sou_units},
      initial_module: Board,
    }
  end

  defp ten_random_units(position) do
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
      Unit.Catmover.new(position),
      Unit.Maycorn.new(position),
      Unit.Spikeder.new(position),
      Unit.Busybody.new(position),
      Unit.Howloo.new(position),
      Unit.Antente.new(position),
    ]) |> Enum.take(10)
    [Unit.Monarch.new(position) | units]
  end

  defp random_terrain(dimensions) do
    gen_terrain(
      %{},
      dimensions,
      Enum.random(0..elem(dimensions, 0)) + 1
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
  def new() do
    units = %{
      north: starting_units(:north),
      south: starting_units(:south)
    }
    terrain = [
      {{1, 2}, :block},
      {{4, 2}, :water},
    ]
    %Board.Configuration{
      dimensions: {5, 5},
      initial_module: Jobfair,
      army_size: 8,
      units: units,
      terrain: terrain,
    }
  end

  defp starting_units(position) do
    [
      Unit.Monarch.new(position),
      Unit.Tactician.new(position),
      Unit.Busybody.new(position),
      Unit.Explody.new(position),
      Unit.Pushie.new(position),
      Unit.Mediacreep.new(position),
      Unit.Sackboom.new(position),
      Unit.Spikeder.new(position),
      Unit.Howloo.new(position),
      Unit.Catmover.new(position),
      Unit.Antente.new(position),
      Unit.new(position, :dogatron, 1, 0, :nil, %{death: Ability.Upgrade}),
      Unit.new(position, :poisonblade, 3, 4, :nil, %{death: Ability.Poisonblade}),
      Unit.new(position, :rowburninator, 3, 2, Ability.Rowburn),
      Unit.new(position, :bezerker, 9, 2),
      Unit.new(position, :sparky, 1, 0, Ability.Copyleft),
      Unit.new(position, :tim, 1, 8),
    ]
  end

end

defmodule Board.Configuration.Chain do
  @behaviour Board.Configuration
  @doc """
  Returns ten standard units in a random order
  """

  @impl Board.Configuration
  def new() do
    units = %{
      north: starting_units(:north),
      south: starting_units(:south),
    }
    terrain = [
      {{0, 0}, :water},
      {{6, 6}, :water},
      {{0, 6}, :water},
      {{6, 0}, :water},
      {{2, 2}, :block},
      {{4, 4}, :block},
    ]
    %Board.Configuration{
      dimensions: {7, 7},
      units: units,
      terrain: terrain,
      initial_module: Board,
    }
  end

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
end
