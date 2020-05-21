defmodule Yagg.Board.Unit do
  alias __MODULE__
  @enforce_keys [:attack, :defense, :name, :position]
  @derive {Poison.Encoder, only: [:name, :attack, :defense, :ability, :position]}
  defstruct [:ability | @enforce_keys]

  def new(position, name, attack, defense, ability \\ :nil) do
    %Unit{position: position, name: name, attack: attack, defense: defense, ability: ability}
  end

  @doc """
  Returns ten standard units in a random order
  """
  def starting_units(position) do
    Enum.shuffle([
      new(position, :monarch, 2, 1),
      new(position, :general, 4, 3),
      new(position, :bezerker, 5, 1),
      new(position, :fullarmorcoward, 1, 5),
      new(position, :recruit, 2, 3),
      new(position, :pacifist, 1, 4),
      new(position, :solid, 3, 3),
      new(position, :triggerhappy, 3, 1),
    ])
  end
end
