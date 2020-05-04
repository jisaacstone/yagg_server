defmodule Yagg.Game.Unit do
  alias __MODULE__
  @derive {Poison.Encoder, only: [:name, :attack, :defense, :abilities]}
  defstruct [
    attack: :nil,
    defense: :nil,
    name: "nil",
    abilities: [],
    player: :nil
  ]

  def new(player, name, attack, defense) do
    %Unit{player: player, name: name, attack: attack, defense: defense}
  end

  @doc """
  Returns ten standard units in a random order
  """
  def starting_units(player) do
    Enum.shuffle([
      new(player, :monarch, 2, 1),
      new(player, :general, 4, 3),
      new(player, :bezerker, 5, 1),
      new(player, :fullarmorcoward, 1, 5),
      new(player, :recruit, 2, 3),
      new(player, :pacifist, 1, 4),
      new(player, :solid, 3, 3),
      new(player, :novice, 3, 2),
      new(player, :triggerhappy, 3, 1),
      new(player, :cannonfodder, 1, 2),
    ])
  end
end
