alias Yagg.Board
alias Yagg.Unit
alias Yagg.Table.Player
alias Yagg.Board.Action
alias Yagg.Board.Grid

defmodule Yagg.AI.Choices do
  @spec move(Board.t, Player.position) :: struct
  def move(board, position) do
    chs = choices(board, position)
    if chs == %{place: [], move: [], ability: []} do
      IO.inspect({:no_choices, board, position})
      concede(owned_units(board.grid, position))
    else 
      Enum.random(chs.place ++ chs.move ++ chs.ability)
    end
  end

  def choices(board, position) do
    pc = place_choices(board.grid, board.dimensions, board.hands[position], position)
    units = owned_units(board.grid, position)
    mc = move_choices(units, board, position)
    ac = ability_choices(board.grid, units)
    %{place: pc, move: mc, ability: ac}
  end

  defp owned_units(grid, position) do
    Enum.filter(
      grid,
      fn
        ({coord, %Unit{position: ^position} = unit}) -> {coord, unit}
        _ -> false
      end
    )
  end

  # PC
  defp place_choices(_grid, {_width, _height}, [], _position), do: []
  defp place_choices(grid, {width, height}, hand, position) do
    os = open_squares(grid, width, height, position)
    pc_combinations(Map.keys(hand), os, [])
  end

  defp pc_combinations([], _, place_actions), do: place_actions
  defp pc_combinations([index|indicies], os, place_actions) do
    place_actions = os_combinations(index, os, place_actions)
    pc_combinations(indicies, os, place_actions)
  end

  defp os_combinations(_, [], place_actions), do: place_actions
  defp os_combinations(index, [{x, y}|os], place_actions) do
    action = %Action.Place{index: index, x: x, y: y}
    os_combinations(index, os, [action|place_actions])
  end

  defp open_squares(grid, width, height, position) do
    ys = y_rows(height, position)
    Enum.reduce(
      0..(width - 1),
      [],
      fn(x, options) ->
        Enum.reduce(
          ys,
          options,
          fn (y, options) ->
            case Map.has_key?(grid, {x, y}) do
              true -> options
              false -> [{x, y} | options]
            end
          end
        )
      end
    )
  end

  defp y_rows(height, :north), do: [height - 1, height - 2]
  defp y_rows(_, :south), do: [0, 1]

  # MC
  defp move_choices(units, board, position) do
    Enum.map(units, fn(u) -> unit_choices(u, board, position) end) |> Enum.concat()
  end

  defp unit_choices({_, %{attack: :immobile}}, _, _), do: []
  defp unit_choices({{fx, fy}, %{attack: a}}, board, position) do
    combat_repeat = a / 3 |> ceil()
    Enum.reduce(
      Grid.surrounding({fx, fy}),
      [],
      fn({_, {tx, ty}}, moves) ->
        move = %Action.Move{from_x: fx, from_y: fy, to_x: tx, to_y: ty}
        case can_move_to(Grid.thing_at(board, {tx, ty}), position) do
          :false ->
            moves
          :true -> 
            [move | moves]
          %Unit{} ->
            List.duplicate(move, combat_repeat) ++ moves
        end
      end
    )
  end

  defp can_move_to(:nil, _), do: :true
  defp can_move_to(%Unit{position: pos}, pos), do: :false
  defp can_move_to(%Unit{} = unit, _), do: unit
  defp can_move_to(_, _), do: :false

  # AC
  defp ability_choices(grid, units) do
    Enum.reduce(
      units,
      [],
      fn(u, a) -> unit_action(grid, u, a) end
    )
  end

  defp unit_action(_, {_, %Unit{ability: :nil}}, actions), do: actions
  defp unit_action(_, {_, %Unit{ability: Unit.Ability.Concede}}, actions), do: actions
  defp unit_action(_, {_, %Unit{name: :shenamouse}}, actions), do: actions
  defp unit_action(grid, {{x, y}, %Unit{name: :burninator, position: pos}}, actions) do
    {us, them} = Enum.reduce(
      grid,
      {0, 0},
      fn
        ({{_, ^y}, %{position: ^pos}}, {u, t}) -> {u + 1, t}
        ({{_, ^y}, %{position: _}}, {u, t}) -> {u, t + 1}
        (_, u_t) -> u_t
      end
    )
    case them - us do
      n when n <= 0 -> actions
      n -> 
        action = %Action.Ability{x: x, y: y}
        List.duplicate(action, n) ++ actions
    end
  end
  defp unit_action(grid, {{x, y}, %Unit{name: :pushie, position: pos}}, actions) do
    {us, them} = Enum.reduce(
      Enum.map(Grid.surrounding({x, y}), fn({_, coord}) -> Map.get(grid, coord) end),
      {0, 0},
      fn
        (%{position: ^pos}, {u, t}) -> {u + 1, t}
        (%{position: _}, {u, t}) -> {u, t + 1}
        (_, u_t) -> u_t
      end
    )
    case them - us do
      n when n <= 0 -> actions
      n -> 
        action = %Action.Ability{x: x, y: y}
        List.duplicate(action, n) ++ actions
    end
  end
  defp unit_action(_, {{x, y}, %Unit{}}, actions) do
    action = %Action.Ability{x: x, y: y}
    [action | actions]
  end

  defp concede([{{x, y}, %Unit{name: :monarch}}|_]) do
    %Action.Ability{x: x, y: y}
  end
  defp concede([_|units]) do
    concede(units)
  end
end
