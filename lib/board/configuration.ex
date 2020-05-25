alias Yagg.Table.Player
alias Yagg.Unit
alias Yagg.Board.Actions.Ability
alias Yagg.Board

defmodule Yagg.Board.Configuration do
  @callback starting_units(Player.position()) :: [Unit.t, ...]
  @callback terrain() :: [{Board.coord(), Board.terrain()}]

  def all() do
    [
      Board.Configuration.Standard,
      Board.Configuration.Chain,
    ]
  end
end

defmodule Configuration.Standard do
  @behaviour Board.Configuration
  @doc """
  Returns ten standard units in a random order
  """

  @impl Board.Configuration
  def starting_units(position) do
    Enum.shuffle([
      Unit.new(position, :monarch, 1, 0, Ability.Concede, %{death: Ability.Concede}),
      Unit.new(position, :general, 5, 4),
      Unit.new(position, :bezerker, 7, 2),
      Unit.new(position, :fullarmorcoward, 1, 6),
      Unit.new(position, :explody, 3, 2, :nil, %{death: Ability.Selfdestruct}),
      Unit.new(position, :colburninator, 1, 2, Ability.Colburn),
      Unit.new(position, :poisonblade, 3, 4, :nil, %{death: Ability.Poisonblade}),
      Unit.new(position, :rowburninator, 3, 2, Ability.Rowburn),
    ])
  end

  @impl Board.Configuration
  def terrain() do
    [
      {{1, 3}, :water},
      {{3, 3}, :water},
    ]
  end
end

defmodule Configuration.Chain do
  @behaviour Board.Configuration
  @doc """
  Returns ten standard units in a random order
  """

  @impl Board.Configuration
  def starting_units(position) do
    Enum.shuffle([
      Unit.new(position, :monarch, 1, 0, Ability.Concede, %{death: Ability.Concede}),
      Unit.new(position, :general, 5, 4),
      Unit.new(position, :bezerker, 7, 2),
      Unit.new(position, :fullarmorcoward, 1, 6),
      Unit.new(position, :explody, 3, 2, :nil, %{death: Ability.Selfdestruct}),
      Unit.new(position, :colburninator, 1, 2, Ability.Colburn),
      Unit.new(position, :poisonblade, 3, 4, :nil, %{death: Ability.Poisonblade}),
      Unit.new(position, :rowburninator, 3, 2, Ability.Rowburn),
    ])
  end

  @impl Board.Configuration
  def terrain() do
    [
      {{1, 3}, :water},
      {{3, 3}, :water},
    ]
  end
end
