alias Yagg.Table.Player
alias Yagg.Unit
alias Yagg.Board.Action.Ability
alias Yagg.Board

defmodule Yagg.Board.Configuration do
  @callback starting_units(Player.position()) :: [Unit.t, ...]
  @callback terrain() :: [{Board.coord(), Board.terrain()}]

  def all() do
    %{
      "alpha" => Board.Configuration.Default,
      "beta" => Board.Configuration.Chain,
    }
  end
end

defmodule Board.Configuration.Default do
  @behaviour Board.Configuration
  @doc """
  Returns ten standard units in a random order
  """

  @impl Board.Configuration
  def starting_units(position) do
    Enum.shuffle([
      Unit.new(position, :monarch, 1, 0, Ability.Concede, %{death: Ability.Concede}),
      Unit.new(position, :general, 5, 4, :nil, %{move: Ability.Manuver}),
      Unit.new(position, :bezerker, 7, 2),
      Unit.new(position, :fullarmorcoward, 1, 6, :nil, %{death: Ability.Secondwind}),
      Unit.new(position, :explody, 3, 2, :nil, %{death: Ability.Selfdestruct}),
      Unit.new(position, :mosh, 3, 0, Ability.Push),
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
      Unit.new(position, :commander, 3, 4, Ability.Manuver),
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
