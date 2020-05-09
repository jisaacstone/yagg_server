defmodule Yagg.Game.Player do
  alias __MODULE__
  @derive {Poison.Encoder, only: [:name, :position]}
  defstruct [
    name: "nil",
    position: :north,
    event_listener: :nil,
  ]

  def new(name, position) do
    %Player{name: name, position: position}
  end

  def by_name(game, name) do
    case game.players do
      [%Player{name: ^name} = player | _] -> player
      [_, %Player{name: ^name} = player | _] -> player
      other ->
        IO.inspect([other, name, game.players])
        :notfound
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
