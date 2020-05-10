defmodule Yagg.Game.Unit do
  alias __MODULE__
  @derive {Poison.Encoder, only: [:id, :name, :attack, :defense, :abilities]}
  @enforce_keys [:attack, :defense, :name, :position, :id]
  defstruct [:abilities | @enforce_keys]

  def new(position, name, attack, defense, id \\ :nil) do
    %Unit{position: position, name: name, attack: attack, defense: defense, id: id}
  end

  def by_id(board, unit_id) do
    case board.units[unit_id] do
      :nil -> :nil
      coords ->
        case board.features[coords] do
          %Unit{} = unit -> {unit, coords}
          _other -> :dead
        end
    end
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
      new(position, :novice, 3, 2),
      new(position, :triggerhappy, 3, 1),
      new(position, :cannonfodder, 1, 2),
    ])
  end
end
