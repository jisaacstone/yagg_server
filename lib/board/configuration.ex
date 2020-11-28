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

  @opaque units :: %{north: [Unit.t], south: [Unit.t]}

  @type t :: %Configuration{
    dimensions: {5..9, 5..9},
    initial_module: Jobfair | Board,
    units: units,
    terrain: any,
  }

  @callback new() :: t
  @callback name() :: String.t
  @callback description() :: String.t

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
    configs = [
      Board.Configuration.Random,
      Board.Configuration.Alpha,
      Board.Configuration.Ice,
    ]
    Enum.map(configs, &describe(&1))
  end

  defp describe(module) do
    %{
      name: module.name(),
      description: module.description(),
      module: module
    }
  end
end

defmodule Board.Configuration.Random do
  @behaviour Board.Configuration

  @impl Board.Configuration
  def name(), do: "random"

  @impl Board.Configuration
  def description(), do: "random sized board with random units"

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
      Unit.Antente.new(position),
      Unit.Burninator.new(position),
      Unit.Busybody.new(position),
      Unit.Catmover.new(position),
      Unit.Dogatron.new(position),
      Unit.Electromouse.new(position),
      Unit.Explody.new(position),
      Unit.Howloo.new(position),
      Unit.Maycorn.new(position),
      Unit.Mediacreep.new(position),
      Unit.Poisonblade.new(position),
      Unit.Pushie.new(position),
      Unit.Sackboom.new(position),
      Unit.Shenamouse.new(position),
      Unit.Sparky.new(position),
      Unit.Spikeder.new(position),
      Unit.Tactician.new(position),
      Unit.Tinker.new(position),
      Unit.new(position, :bezerker, 9, 2),
      Unit.new(position, :chopper, 7, 4),
      Unit.new(position, :rollander, 1, 6, :nil, %{death: Ability.Secondwind}),
      Unit.new(position, :tim, 1, 8),
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
  def name(), do: "fivers"

  @impl Board.Configuration
  def description(), do: "five by five grid"

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
      Unit.Antente.new(position),
      Unit.Burninator.new(position),
      Unit.Busybody.new(position),
      Unit.Catmover.new(position),
      Unit.Dogatron.new(position),
      Unit.Electromouse.new(position),
      Unit.Explody.new(position),
      Unit.Howloo.new(position),
      Unit.Maycorn.new(position),
      Unit.Mediacreep.new(position),
      Unit.Monarch.new(position),
      Unit.Poisonblade.new(position),
      Unit.Pushie.new(position),
      Unit.Sackboom.new(position),
      Unit.Shenamouse.new(position),
      Unit.Sparky.new(position),
      Unit.Spikeder.new(position),
      Unit.Tactician.new(position),
      Unit.Tinker.new(position),
      Unit.new(position, :bezerker, 9, 2),
      Unit.new(position, :tim, 1, 8),
    ]
  end

end

defmodule Board.Configuration.Ice do
  @behaviour Board.Configuration

  @impl Board.Configuration
  def name(), do: "iceslide"

  @impl Board.Configuration
  def description(), do: "all units slide"

  @impl Board.Configuration
  def new() do
    units = %{
      north: starting_units(:north),
      south: starting_units(:south),
    }
    terrain = [
      {{0, 0}, :water},
      {{1, 6}, :water},
      {{2, 4}, :water},
      {{3, 2}, :water},
      {{4, 5}, :water},
      {{5, 3}, :water},
      {{6, 1}, :water},
      {{7, 7}, :water},
    ]
    %Board.Configuration{
      dimensions: {8, 8},
      units: units,
      terrain: terrain,
      initial_module: Jobfair,
      army_size: 12,
    }
  end

  def starting_units(position) do
    Enum.map(
      [
        Unit.Monarch.new(position),
        Unit.new(position, :bezerker, 9, 0),
        Unit.new(position, :bezerker, 9, 0),
        Unit.new(position, :chopper, 7, 2),
        Unit.new(position, :chopper, 7, 2),
        Unit.new(position, :tim, 1, 8),
        Unit.new(position, :tim, 1, 8),
        Unit.new(position, :rollander, 3, 6),
        Unit.new(position, :rollander, 3, 6),
        Unit.Antente.new(position),
        Unit.Antente.new(position),
        Unit.Explody.new(position),
        Unit.Explody.new(position),
        Unit.Pushie.new(position),
        Unit.Pushie.new(position),
        Unit.Poisonblade.new(position),
        Unit.Poisonblade.new(position),
        Unit.Burninator.new(position),
        Unit.Burninator.new(position),
        Unit.Shenamouse.new(position),
        Unit.Shenamouse.new(position),
      ],
      &Unit.set_trigger(&1, :move, Unit.Ability.Slide)
    )
  end
end
