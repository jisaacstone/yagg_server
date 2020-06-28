alias Yagg.Table

defmodule Table.Player do
  alias __MODULE__
  @derive {Poison.Encoder, only: [:name, :position]}
  @enforce_keys [:name, :position]
  defstruct @enforce_keys

  @type position() :: :north | :south
  @type t() :: %Player{name: String.t(), position: position()} 

  def new(name, position) do
    %Player{name: name, position: position}
  end

  @spec opposite(position) :: position
  def opposite(:north), do: :south
  def opposite(:south), do: :north

  @spec by_name(Table.t, String.t) :: t | :notfound
  def by_name(game, name) do
    case game.players do
      [%Player{name: ^name} = player | _] -> player
      [_, %Player{name: ^name} = player | _] -> player
      _ -> :notfound
    end
  end
end
