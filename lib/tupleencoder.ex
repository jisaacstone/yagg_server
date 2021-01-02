defmodule Yagg.TupleEncoder do
  defimpl Poison.Encoder, for: Tuple do
    # table {position, player} tuples
    def encode({x, %{id: _, name: _} = player}, options) when is_atom(x) do
      Poison.Encoder.Map.encode(%{player: player, position: x}, options)
    end
    # grid {x, y} coord encoder
    def encode({x, y}, options) when is_integer(x) and is_integer(y) do
      Poison.Encoder.Map.encode(%{x: x, y: y}, options)
    end
  end
end
