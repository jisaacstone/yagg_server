alias Yagg.Board.Actions.Ability
alias Yagg.Action

defmodule Yagg.Unit do
  alias __MODULE__
  @enforce_keys [:attack, :defense, :name, :position]
  defstruct [:ability, :triggers | @enforce_keys]

  defimpl Poison.Encoder, for: Unit do
    def encode(%Unit{} = unit, opts) do
      %{
        attack: unit.attack,
        defense: unit.defense,
        name: unit.name,
        player: unit.position,
        ability: Action.describe(unit.ability),
        triggers: Enum.map(unit.triggers || %{}, fn({k, v}) -> {k, Action.describe(v)} end) |> Enum.into(%{})
      } |> Poison.Encoder.Map.encode(opts)
    end
  end

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
