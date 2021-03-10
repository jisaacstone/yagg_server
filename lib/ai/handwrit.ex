alias Yagg.Unit
alias Yagg.Board
alias Yagg.Board.Grid
alias Yagg.AI

defmodule AI.Handwrit do
  def turn(board, position) do
    units = AI.Choices.owned_units(board.grid, position)
    weights = Enum.reduce(
      units,
      AI.Weights.new(),
      fn ({coord, unit}, weights) ->
        weights = weigh_attack(board, coord, unit, weights)
        AI.Handwrit.Ability.weigh(board, coord, unit, weights)
      end
    )
    weights = AI.Handwrit.Place.weigh(board, position, weights)
    case AI.Weights.random(weights) do
      {:ok, choice} -> choice
      {:err, _} -> AI.Choices.move(board, position)
    end
  end

  def placement(board, position) do
    AI.Handwrit.Place.placement(board, position)
  end

  @spec weigh_attack(Board.t, Grid.coord, Unit.t, AI.Weights.t(AI.Weights.action)) :: AI.Weights.t(AI.Weights.action)
  defp weigh_attack(_, _, %{attack: :immobile}, weights), do: weights
  defp weigh_attack(board, coord, unit, weights) do
    Grid.surrounding(coord) |> Enum.reduce(
      weights,
      fn({dir, next}, weights) -> weigh_direction(board, coord, dir, next, unit, weights) end
    )
  end

  @spec weigh_direction(Board.t, Grid.coord, atom, Grid.coord, Unit.t, AI.Weights.t(AI.Weights.action)) :: AI.Weights.t(AI.Weights.action)
  defp weigh_direction(board, coord, dir, next, %{position: pos} = unit, weights) do
    front = Grid.cardinal(pos, :front)
    case Grid.thing_at(board, next) do
      %Unit{position: ^pos} -> weights
      :water -> weights
      :out_of_bounds -> weights
      :nil -> AI.Weights.move(weights, (if dir == front, do: unit.attack, else: 1), coord, next)
      %Unit{} -> AI.Weights.move(weights, unit.attack * ceil(unit.attack / 2), coord, next)
      :block -> case Grid.thing_in_direction(board, next, dir) do
        :nil -> AI.Weights.move(weights, (if dir == front, do: unit.attack, else: 1), coord, next)
        _ -> weights
      end
    end
  end
end
