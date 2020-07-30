alias Yagg.Board
alias Yagg.Unit
alias Yagg.Table.Player
alias Yagg.Board.Action
alias Yagg.Board.Grid

defmodule Yagg.AI.Choices do
  @spec move(Board.t, Player.position) :: struct
  def move(board, position) do
    chs = choices(board, position)
    Enum.random(chs.place ++ chs.move ++ chs.ability)
  end

  def choices(board, position) do
    pc = place_choices(board.grid, board.dimensions, board.hands[position], position)
    units = owned_units(board.grid, position)
    mc = move_choices(units, board, position)
    ac = ability_choices(units)
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

  defp unit_choices({{fx, fy}, _}, board, position) do
    Enum.reduce(
      Grid.surrounding({fx, fy}),
      [],
      fn({_, {tx, ty}}, moves) ->
        if can_move_to(Grid.thing_at(board, {tx, ty}), position) do
          move = %Action.Move{from_x: fx, from_y: fy, to_x: tx, to_y: ty}
          [move | moves]
        else
          moves
        end
      end
    )
  end

  defp can_move_to(:nil, _), do: :true
  defp can_move_to(%Unit{position: pos}, pos), do: :false
  defp can_move_to(%Unit{}, _), do: :true
  defp can_move_to(_, _), do: :false

  # AC
  defp ability_choices(units) do
    Enum.reduce(
      units,
      [],
      fn(u, a) -> unit_action(u, a) end
    )
  end

  defp unit_action({_, %Unit{ability: :nil}}, actions), do: actions
  defp unit_action({_, %Unit{name: :monarch}}, actions), do: actions
  defp unit_action({{x, y}, %Unit{}}, actions) do
    action = %Action.Ability{x: x, y: y}
    [action | actions]
  end
end