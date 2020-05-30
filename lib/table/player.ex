defmodule Yagg.Table.Player do
  alias __MODULE__
  @derive {Poison.Encoder, only: [:name, :position]}
  @enforce_keys [:name, :position]
  defstruct @enforce_keys

  @type position() :: :north | :south
  @type t() :: %Player{name: String.t(), position: position()} 

  def new(name, position) do
    %Player{name: name, position: position}
  end

  def opposite(:north), do: :south
  def opposite(:south), do: :north

  def by_name(game, name) do
    case game.players do
      [%Player{name: ^name} = player | _] -> player
      [_, %Player{name: ^name} = player | _] -> player
      _ -> :notfound
    end
  end

  def starting_squares(%Player{position: :north}, _board) do
    [{0,4}, {1,4}, {2,4}, {3,4}, {4,4},
     {0,3}, {1,3}, {2,3}, {3,3}, {4,3}]
  end
  def starting_squares(%Player{position: :south}, _board) do
    [{0,1}, {1,1}, {2,1}, {3,1}, {4,1},
     {0,0}, {1,0}, {2,0}, {3,0}, {4,0}]
  end
end
