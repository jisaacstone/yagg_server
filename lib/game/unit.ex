defmodule Yagg.Game.Unit do
  alias __MODULE__
  defstruct [
    attack: :nil,
    defense: :nil,
    name: "nil",
    abilities: []
  ]

  def new(name, attack, defense) do
    %Unit{name: name, attack: attack, defense: defense}
  end

  @doc """
  Returns ten standard units in a random order
  """
  def starting_units() do
    Enum.shuffle([
      new(:monarch, 2, 1),
      new(:general, 4, 3),
      new(:bezerker, 5, 1),
      new(:fullarmorcoward, 1, 5),
      new(:recruit, 2, 3),
      new(:pacifist, 1, 4),
      new(:solid, 3, 3),
      new(:novice, 3, 2),
      new(:triggerhappy, 3, 1),
      new(:cannonfodder, 1, 2),
    ])
  end
end
