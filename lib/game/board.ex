alias Yagg.Game.Unit
alias Yagg.Event

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
        |> Map.new(fn({{x, y}, f}) -> {"#{x},#{y}", encode_feature(f)} end)
      Poison.Encoder.Map.encode(
        %{width: board.width,
          height: board.height,
          features: encodeable},
        options
      )
    end

    defp encode_feature(%Unit{id: id}), do: id
    defp encode_feature(other), do: other
  end

  def new() do
    %Board{width: 5, height: 5, units: %{}, features: %{{1, 2} => :water, {3, 2} => :water}}
  end

  def place(%Board{features: features, units: units} = board, %Unit{} = unit, x, y) do
    case features[{x, y}] do
      :nil -> {
          :ok,
          %{board |
            features: Map.put_new(features, {x, y}, unit),
            units: Map.put(units, unit.id, {x, y})}}
      _something -> {:err, :occupied}
    end
  end
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

  def move(board, position, unit_id, to_x, to_y) do
    case Unit.by_id(board, unit_id) do
      :nil -> {:err, :notonboard}
      :dead -> {:err, :dead}
      {%{position: ^position} = unit, {x, y}} ->
        unless can_move?({x, y}, {to_x, to_y}) do
          {:err, :illegal}
        else
          case board.features[{to_x, to_y}] do
            :water -> {:err, :illegal}
            :nil -> 
              {board, events} = do_move(board, unit, {x, y}, {to_x, to_y})
              {:ok, board, events}
            feature -> 
              do_battle(board, unit, feature, {x, y}, {to_x, to_y})
          end
        end
      {_unit, _coords} -> {:err, :illegal}
    end
  end

  defp can_move?({x, y}, {to_x, to_y}) do
    Enum.sort([abs(x - to_x), abs(y - to_y)]) == [0, 1]
  end

  defp do_move(board, unit, from, to) do
    units = %{board.units | unit.id => to}
    features = board.features
      |> Map.delete(from)
      |> Map.put_new(to, unit)
    {
      %{board | units: units, features: features},
      [Event.new(:unit_moved, %{id: unit.id, from: from, to: to})]
    }
  end

  defp unit_death(board, unit) do
    {coords, units} = Map.pop!(board.units, unit.id)
    features = Map.delete(board.features, coords)
    {
      %{board | units: units, features: features},
      [Event.new(:unit_died, %{id: unit.id})]
    }
  end

  defp do_battle(board, unit, opponent, from, to) do
    cond do
      unit.attack > opponent.defense ->
        {board, e1} = unit_death(board, opponent)
        {board, e2} = do_move(board, unit, from, to)
        {state, events} = unless opponent.name == :monarch do
          {:ok, e1 ++ e2}
        else
          {:gameover, [Event.new(:gameover, %{winner: unit.position}) | e1] ++ e2}
        end
        {state, board, events}
      unit.attack == opponent.defense ->
        {board, e1} = unit_death(board, opponent)
        {board, e2} = unit_death(board, unit)
        {state, events} = case {unit.name, opponent.name} do
          {:monarch, :monarch} -> {:gameover, [Event.new(:gameover, %{winner: :draw}) | e1] ++ e2}
          {:monarch, _} -> {:gameover, [Event.new(:gameover, %{winner: opponent.position}) | e1] ++ e2}
          {_, :monarch} -> {:gameover, [Event.new(:gameover, %{winner: unit.position}) | e1] ++ e2}
          _ -> {:ok, e1 ++ e2}
        end
        {state, board, events}
      unit.attack < opponent.defense ->
        {board, events} = unit_death(board, unit)
        {state, events} = unless unit.name == :monarch do
          {:ok, events}
        else
          {:gameover, [Event.new(:gameover, %{winner: unit.position}) | events]}
        end
        {state, board, events}
    end
  end
end
