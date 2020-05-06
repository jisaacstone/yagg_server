defmodule Yagg.Game.Board do
  alias __MODULE__
  defstruct [
    width: 5,
    height: 5,
    features: %{},
    units: %{},
  ]

  defimpl Poison.Encoder, for: Board do
    def encode(%Board{features: features} = board, options) do
      encodeable = features
        |> Map.to_list()
        |> Map.new(fn({{x, y}, f}) -> {"#{x},#{y}", f} end)
      Poison.Encoder.Map.encode(
        %{width: board.width,
          height: board.height,
          features: encodeable},
        options
      )
    end
  end

  def new() do
    %Board{width: 5, height: 5, units: %{}, features: %{{1, 2} => :water, {3, 2} => :water}}
  end

  # assumes there can only be one feature per space
  def place(%Board{features: features} = board, feature, x, y) do
    case features[{x, y}] do
      :nil -> {:ok, %{board | features: Map.put_new(features, {x, y}, feature)}}
      _something -> {:err, :occupied}
    end
  end

  def remove(%Board{features: features} = board, x, y) do
    case features[{x, y}] do
      :nil -> {:err, :noexist}
      _something -> {:ok, %{board | features: Map.delete(features, {x, y})}}
    end
  end
end
