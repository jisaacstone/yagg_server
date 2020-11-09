defmodule Yagg.TupleEncoder do
  defimpl Poison.Encoder, for: Tuple do
    # table {position, player} tuples
    def encode({x, %{id: id, name: name}}, options) when is_atom(x) do
      Poison.Encoder.Map.encode(%{id: id, name: name, position: x}, options)
    end
    # grid {x, y} coord encoder
    def encode({x, y}, options) when is_integer(x) and is_integer(y) do
      Poison.Encoder.Map.encode(%{x: x, y: y}, options)
    end
  end
end
