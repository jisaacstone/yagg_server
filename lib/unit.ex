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
      new(position, :monarch, 2, 1, :nil, %{death: Ability.Lose}),
      new(position, :general, 4, 3),
      new(position, :bezerker, 5, 1),
      new(position, :fullarmorcoward, 1, 5),
      new(position, :explody, 2, 3, :nil, %{death: Ability.Selfdestruct}),
      new(position, :pacifist, 1, 4),
      new(position, :solid, 3, 3),
      new(position, :triggerhappy, 3, 1),
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
