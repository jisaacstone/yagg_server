alias Yagg.Unit
alias Yagg.Board
alias Yagg.Board.Grid
alias Yagg.Board.Action
alias Yagg.Table.Player
alias Yagg.AI

defmodule AI.Attack do
  def turn(board, position) do
    units = AI.Choices.owned_units(board.grid, position)
    weights = Enum.reduce(
      units,
      AI.Weights.new(),
      fn ({coord, unit}, weights) ->
        weights = weigh_attack(board, coord, unit, weights)
        weigh_ability(board, coord, unit, weights)
      end
    )
    random = AI.Choices.choices(board, position)
    Enum.each(random.place, fn(a) -> AI.Weights.add(weights, 1, a) end)
    case AI.Weights.random(weights) do
      {:ok, choice} -> choice
      {:err, _} -> AI.Choices.move(board, position)
    end
  end

  @spec weigh_attack(Board.t, Grid.coord, Unit.t, AI.Weights.t) :: AI.Weights.t
  defp weigh_attack(_, _, %{attack: :immobile}, weights), do: weights
  defp weigh_attack(board, coord, unit, weights) do
    Grid.surrounding(coord) |> Enum.reduce(
      weights,
      fn({dir, next}, weights) -> weigh_direction(board, coord, dir, next, unit, weights) end
    )
  end

  @spec weigh_direction(Board.t, Grid.coord, atom, Grid.coord, Unit.t, AI.Weights.t) :: AI.Weights.t
  defp weigh_direction(board, coord, dir, next, %{position: pos} = unit, weights) do
    front = Grid.cardinal(pos, :front)
    case Grid.thing_at(board, next) do
      %Unit{position: ^pos} -> weights
      :water -> weights
      :out_of_bounds -> weights
      :nil -> move(coord, next, (if dir == front, do: unit.attack, else: 1), weights)
      %Unit{} -> move(coord, next, unit.attack * ceil(unit.attack / 2), weights)
      :block -> case Grid.thing_in_direction(board, next, dir) do
        :nil -> move(coord, next, (if dir == front, do: unit.attack, else: 1), weights)
        _ -> weights
      end
    end
  end

  @spec move(Grid.coord, Grid.coord, non_neg_integer, AI.Weights.t) :: AI.Weights.t
  defp move({fx, fy}, {tx, ty}, weight, weights) do
    action = %Action.Move{from_x: fx, from_y: fy, to_x: tx, to_y: ty}
    AI.Weights.add(weights, weight, action)
  end

  @spec ability(Grid.coord, non_neg_integer, AI.Weights.t) :: AI.Weights.t
  defp ability({x, y}, weight, weights) do
    action = %Action.Ability{x: x, y: y}
    AI.Weights.add(weights, weight, action)
  end

  defp weigh_ability(_, _, %{ability: :nil}, weights), do: weights
  defp weigh_ability(board, {x, y}, %{name: :burninator, position: pos}, weights) do
    {us, them} = Enum.reduce(
      board.grid,
      {0, 0},
      fn
        ({{_, ^y}, %{position: ^pos}}, {u, t}) -> {u + 1, t}
        ({{_, ^y}, %{position: _}}, {u, t}) -> {u, t + 1}
        (_, u_t) -> u_t
      end
    )
    case them - us do
      n when n <= 0 -> weights
      n -> ability({x, y}, n * n, weights)
    end
  end
  defp weigh_ability(board, {x, y}, %Unit{name: :pushie, position: pos}, weights) do
    {us, them} = Enum.reduce(
      Enum.map(Grid.surrounding({x, y}), fn({_, coord}) -> Map.get(board.grid, coord) end),
      {0, 0},
      fn
        (%{position: ^pos}, {u, t}) -> {u + 1, t}
        (%{position: _}, {u, t}) -> {u, t + 1}
        (_, u_t) -> u_t
      end
    )
    case them - us do
      n when n <= 0 -> weights
      n -> ability({x, y}, n * n, weights)
    end
  end
  defp weigh_ability(board, coord, %{name: name, position: pos}, weights)
  when name == :howloo or name == :maycorn do
    enemy = Player.opposite(pos)
    case Grid.projectile(board, coord, Grid.cardinal(pos, :front)) do
      {_, %Unit{position: ^enemy}} -> ability(coord, 5, weights)
      _ -> weights
    end
  end
  defp weigh_ability(board, coord, %{name: :sparky, position: pos}, weights) do
    case Grid.thing_in_direction(board, coord, {pos, :left}) do
      %Unit{monarch: true} -> weights
      %Unit{} -> ability(coord, 10, weights)
      _ -> weights
    end
  end
  defp weigh_ability(board, coord, %{ability: Unit.Tinker.Tink, position: pos}, weights) do
    scorer = escore(pos)
    score = Grid.thing_in_direction(board, coord, {pos, :left}) |> scorer.()
    score = score + scorer.(Grid.thing_in_direction(board, coord, {pos, :right}))
    if score > 0 do
      ability(coord, score * 5, weights)
    else
      weights
    end
  end
  defp weigh_ability(board, coord, %{ability: Unit.Tinker.Tonk, position: pos}, weights) do
    scorer = escore(pos)
    score = Grid.thing_in_direction(board, coord, {pos, :front}) |> scorer.()
    score = score + scorer.(Grid.thing_in_direction(board, coord, {pos, :back}))
    if score > 0 do
      ability(coord, score * 5, weights)
    else
      weights
    end
  end
  defp weigh_ability(board, coord, %{name: :electromouse, position: pos}, weights) do
    scorer = escore(Player.opposite(pos))
    score = Enum.reduce(
      Grid.surrounding(coord),
      1,
      fn({_, c}, s) -> s + scorer.(Grid.thing_at(board, c)) end
    )
    if score <= 0 do
      weights
    else
      ability(coord, score * score, weights)
    end
  end
  defp weigh_ability(_, coord, _, weights) do
    ability(coord, 1, weights)
  end

  defp escore(pos) do
    fn
      (%Unit{position: ^pos}) -> 1
      (%Unit{}) -> -1
      _ -> 0
    end
  end
end
