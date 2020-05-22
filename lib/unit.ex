alias Yagg.Board.Actions.Ability

defmodule Yagg.Unit do
  alias __MODULE__
  @enforce_keys [:attack, :defense, :name, :position]
  @derive {Poison.Encoder, only: [:name, :attack, :defense, :ability, :position]}
  defstruct [:ability, :triggers | @enforce_keys]

  def new(position, name, attack, defense, ability \\ :nil, triggers \\ %{}) do
    %Unit{position: position, name: name, attack: attack, defense: defense, ability: ability, triggers: triggers}
  end

  @doc """
  Returns ten standard units in a random order
  """
  def starting_units(position) do
    Enum.shuffle([
      new(position, :monarch, 1, 0, Ability.Concede, %{death: Ability.Concede}),
      new(position, :general, 5, 4),
      new(position, :bezerker, 7, 2),
      new(position, :fullarmorcoward, 1, 6),
      new(position, :explody, 3, 2, :nil, %{death: Ability.Selfdestruct}),
      new(position, :colburninator, 1, 2, Ability.Colburn),
      new(position, :poisonblade, 3, 4, :nil, %{death: Ability.Poisonblade}),
      new(position, :rowburninator, 3, 2, Ability.Rowburn),
    ])
  end

  def deathrattle(unit) do
    if unit.triggers && unit.triggers[:death] do
      unit.triggers.death
    else
      Ability.NOOP
    end
  end
end
