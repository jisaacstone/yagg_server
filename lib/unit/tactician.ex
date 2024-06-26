alias Yagg.Unit
alias Yagg.Board
alias Yagg.Board.Grid
alias Yagg.Unit.Trigger.AfterMove

defmodule Unit.Tactician do
  @behaviour Unit
  @impl Unit
  def new(position) do
    Unit.new(
      position,
      :tactician,
      5,
      4,
      :nil,
      %{
        move: Unit.Tactician.Manuver
      }
    )
  end

  defmodule Manuver do
    @moduledoc """
    Move all adjacent friendly units in the same direction
    """
    use AfterMove

    @impl AfterMove
    def after_move(%Board{} = board, %{from: from, to: to, unit: %{position: position}}) do
      direction = Grid.direction(from, to)
      coords =
        Grid.surrounding(from)
        |> Enum.into(%{})
        |> order(direction)
      move_units(board, direction, position, coords, [])
    end

    defp order(coord_map, direction) do
      {_first, coord_map} = Map.pop(coord_map, direction)
      Map.values(coord_map)
    end

    defp move_units(board, _direction, _position, [], events), do: {board, events}
    defp move_units(%Board{} = board, direction, position, [from | coords], events) do
      case Board.move(board, position, from, Grid.next(direction, from)) do
        {%Board{} = newboard, newevents} ->
          move_units(newboard, direction, position, coords, events ++ newevents)
        _ -> 
          move_units(board, direction, position, coords, events)
      end
    end
  end
end
