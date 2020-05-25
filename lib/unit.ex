alias Yagg.Board.Actions.Ability
alias Yagg.Action
alias Yagg.Table.Player

defmodule Yagg.Unit do
  alias __MODULE__
  @enforce_keys [:attack, :defense, :name, :position]
  defstruct [:ability, :triggers | @enforce_keys]

  @type t :: %Unit{
    :attack => 1 | 3 | 5 | 7 | 9,
    :defense => 0 | 2 | 4 | 6 | 8,
    :name => atom(),
    :position => Player.position(),
    :ability => module(),
    :triggers => map(),
  }

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


  def deathrattle(unit) do
    if unit.triggers && unit.triggers[:death] do
      unit.triggers.death
    else
      Ability.NOOP
    end
  end
end
