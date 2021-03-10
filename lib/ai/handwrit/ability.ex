alias Yagg.Unit
alias Yagg.Board
alias Yagg.Board.Grid
alias Yagg.Table.Player
alias Yagg.AI.Weights

defmodule Yagg.AI.Handwrit.Ability do
  @spec weigh(Board.t, Grid.coord, Unit.t, Weights.t) :: Weights.t
  def weigh(board, coord, unit, weights) do
    case weigh_ability(board, coord, unit) do
      :skip -> weights
      weight -> Weights.ability(weights, weight, coord)
    end
  end

  defp weigh_ability(_, _, %{ability: :nil}), do: :skip

  defp weigh_ability(board, {_, y}, %{name: :burninator, position: pos}) do
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
      n when n <= 0 -> :skip
      n -> n * n
    end
  end

  defp weigh_ability(board, {x, y}, %Unit{name: :pushie, position: pos}) do
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
      n when n <= 0 -> :skip
      n -> n * n
    end
  end

  defp weigh_ability(board, {x, y}, %Unit{name: :"jacko scare", position: pos}) do
    score = Enum.reduce(
      Enum.map(Grid.surrounding({x, y}), fn({_, coord}) -> Map.get(board.grid, coord) end),
      0,
      fn
        (%{position: ^pos}, s) -> s
        (%{position: _}, s) -> s + s + 1
        (_, s) -> s
      end
    )
    case score do
      0 -> :skip
      s -> s
    end
  end

  defp weigh_ability(board, coord, %{name: name, position: pos})
  when name == :howloo or name == :maycorn do
    enemy = Player.opposite(pos)
    case Grid.projectile(board, coord, Grid.cardinal(pos, :front)) do
      {_, %Unit{position: ^enemy}} -> 5
      _ -> :skip
    end
  end

  defp weigh_ability(board, coord, %{name: :sparky, position: pos}) do
    case Grid.thing_in_direction(board, coord, {pos, :left}) do
      %Unit{monarch: true} -> :skip
      %Unit{} -> 10
      _ -> :skip
    end
  end

  defp weigh_ability(board, coord, %{ability: Unit.Tinker.Tink, position: pos}) do
    scorer = escore(pos)
    score = Grid.thing_in_direction(board, coord, {pos, :left}) |> scorer.()
    score = score + scorer.(Grid.thing_in_direction(board, coord, {pos, :right}))
    if score > 0 do
      score * 5
    else
      :skip
    end
  end

  defp weigh_ability(board, coord, %{ability: Unit.Tinker.Tonk, position: pos}) do
    scorer = escore(pos)
    score = Grid.thing_in_direction(board, coord, {pos, :front}) |> scorer.()
    score = score + scorer.(Grid.thing_in_direction(board, coord, {pos, :back}))
    if score > 0 do
      score * 5
    else
      :skip
    end
  end

  defp weigh_ability(board, coord, %{name: :electromouse, position: pos}) do
    scorer = escore(Player.opposite(pos))
    score = Enum.reduce(
      Grid.surrounding(coord),
      1,
      fn({_, c}, s) -> s + scorer.(Grid.thing_at(board, c)) end
    )
    if score <= 0 do
      :skip
    else
      score * score
    end
  end

  defp weigh_ability(_, _, _) do
    # default
    1
  end

  defp escore(pos) do
    fn
      (%Unit{position: ^pos}) -> 1
      (%Unit{}) -> -1
      _ -> 0
    end
  end
end
