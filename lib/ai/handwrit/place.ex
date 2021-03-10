alias Yagg.Board
alias Yagg.Board.Grid
alias Yagg.Unit
alias Yagg.Table.Player
alias Yagg.AI.Weights
alias Yagg.Board.Action.Place

defmodule Yagg.AI.Handwrit.Place do
  @spec weigh(Board.t, Player.position, Weights.t(Weights.action)) :: Weights.t(Weights.action)
  def weigh(board, position, weights) do
    hand = Map.get(board.hands, position)
    case open_squares(board.grid, board.dimensions, position) do
      [] -> weights
      open -> 
        openrank = rank_open(board, open, position)
        Enum.reduce(
          hand,
          weights,
          fn
            ({index, {unit, :nil}}, weights) ->
              p_weigh(unit, openrank, index, weights)
            ({_, _}, weights) ->
              weights
          end
        )
    end
  end

  @spec placement(Board.t, Player.position) :: [%Place{}]
  def placement(board, position) do
    hand = Map.get(board.hands, position)
    {index, {_, :nil}} = Enum.find(hand, fn({_, {u, _}}) -> u.monarch end)
    case open_squares(board.grid, board.dimensions, position) do
      [] -> {:err, :noopen}
      open ->
        max_place = Enum.random(4..map_size(hand))
        p1 = place_monarch(board, open, position, index)
        open = occupied(open, p1)
        {_, hand} = Map.pop(hand, index)
        do_placement(board, open, hand, position, max_place, [p1])
    end
  end

  defp do_placement(_, [], _, _, _, placements), do: placements
  defp do_placement(_, _, _, _, 0, placements), do: placements
  defp do_placement(board, open, hand, position, max_place, placements) do
    openrank = rank_open(board, open, position)
    weights = hand_weights(hand, openrank, Weights.new())
    case Weights.random(weights) do
      {:err, :no_choices} -> 
        placements
      {:ok, choice}->
        open = occupied(open, choice)
        {_, hand} = Map.pop(hand, choice.index)
        do_placement(board, open, hand, position, max_place - 1, [choice | placements])
    end
  end

  defp occupied([{x, y} | t], %{x: x, y: y}), do: t
  defp occupied([h | t], place), do: [h | occupied(t, place)]

  defp hand_weights(hand, openrank, weights) do
    Enum.reduce(
      hand,
      weights,
      fn
        ({index, {unit, :nil}}, weights) ->
          p_weigh(unit, openrank, index, weights)
        ({_, _}, weights) ->
          weights
      end
    )
  end

  defp p_weigh(%{attack: :immobile}, o_r, i, w), do: p_choose(o_r.defense, 10, i, w)
  defp p_weigh(%{defense: 0} = unit, o_r, i, w), do: p_choose(o_r.attack, unit.attack, i, w)
  defp p_weigh(%{attack: 1} = unit, o_r, i, w), do: p_choose(o_r.defense, unit.defense, i, w)
  defp p_weigh(%{defense: 2} = unit, o_r, i, w), do: p_choose(o_r.attack, unit.attack, i, w)
  defp p_weigh(%{name: :explody}, o_r, i, w), do: p_choose(o_r.attack, 5, i, w)
  defp p_weigh(%{attack: a, defense: d}, o_r, index, w) when is_integer(a) and is_integer(d) do
    {:ok, a_or_d} = Weights.new()
      |> Weights.add(a, :attack)
      |> Weights.add(d, :defense)
      |> Weights.random()
    p_choose(o_r[a_or_d], 5, index, w)
  end

  @spec p_choose(Weights.t(Grid.coord), non_neg_integer, non_neg_integer, Weights.t(Weights.action)) :: Weights.t(Weights.action)
  defp p_choose(choices, weight, index, weights) do
    {:ok, {x, y}} = Weights.random(choices)
    Weights.place(weights, weight, index, {x, y})
  end

  defp open_squares(grid, {width, height}, position) do
    ys = y_rows(height, position)
    Enum.reduce(
      0..(width - 1),
      [],
      fn(x, open) ->
        Enum.reduce(
          ys,
          open,
          fn (y, open) ->
            case Map.get(grid, {x, y}) do
              :nil -> [{x, y} | open]
              _ -> open
            end
          end
        )
      end
    )
  end
  defp y_rows(height, :north), do: [height - 1, height - 2]
  defp y_rows(_, :south), do: [0, 1]

  @spec rank_open(Board.t, [Grid.coord], Player.position) :: %{attack: Weights.t(Grid.coord), defense: Weights.t(Grid.coord)}
  defp rank_open(board, open, position) do
    Enum.reduce(
      open,
      %{attack: Weights.new(), defense: Weights.new()},
      fn(coord, ways) -> 
        {attack, defense} = rank_coord(board, coord, position)
        %{attack: Weights.add(ways.attack, attack, coord), defense: Weights.add(ways.defense, defense, coord)}
      end
    )
  end

  defp rank_coord(board, coord, position) do
    attack = weigh_surround(board, coord, &(weigh_attack(&1, position)))
    defense = weigh_surround(board, coord, &(weigh_defense(&1, position)))
    {attack, defense}
  end

  defp place_monarch(board, open, position, index) do
    options = Enum.reduce(
      open,
      Weights.new(),
      fn(coord, options) ->
        weight = weigh_surround(board, coord, &(weigh_monarch(&1, position)))
        Weights.add(options, weight, coord)
      end
    )
    {:ok, {x, y}} = Weights.random(options)
    %Place{index: index, x: x, y: y}
  end

  def weigh_monarch(:nil, _), do: 1
  def weigh_monarch(:water, _), do: 15
  def weigh_monarch(:block, _), do: 20
  def weigh_monarch(:out_of_bounds, _), do: 50
  def weigh_monarch(%{position: p}, p), do: 80
  def weigh_monarch(%Unit{}, _), do: 0

  def weigh_attack(:nil, _), do: 10
  def weigh_attack(:water, _), do: 1
  def weigh_attack(:block, _), do: 2
  def weigh_attack(:out_of_bounds, _), do: 1
  def weigh_attack(%{position: p}, p), do: 1
  def weigh_attack(%Unit{}, _), do: 35

  def weigh_defense(:nil, _), do: 10
  def weigh_defense(:water, _), do: 1
  def weigh_defense(:block, _), do: 1
  def weigh_defense(:out_of_bounds, _), do: 1
  def weigh_defense(%{monarch: :true, position: p}, p), do: 45
  def weigh_defense(%{position: p}, p), do: 10
  def weigh_defense(%Unit{}, _), do: 25

  def weigh_surround(board, coord, weighfn) do
    Enum.reduce(
      Grid.surrounding(coord),
      0,
      fn({_, coord}, total) -> total + weighfn.(Grid.thing_at(board, coord)) end
    )
  end

end
