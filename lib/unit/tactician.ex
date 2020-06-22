alias Yagg.Unit
alias Yagg.Board
alias Yagg.Board.Grid
alias Yagg.Board.Action.Ability

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
    all adjacent friendly units move in the same direction,
    north, south, east, west
    """
    use Ability

    @impl Ability
    def resolve(%Board{} = board, opts) do
      case {opts[:from], opts[:to]} do
        {_,:nil} -> {:err, :misconfigured}
        {:nil,_} -> {:err, :misconfigured}
        {from, to} ->
          direction = Grid.direction(from, to)
          coords =
            Grid.surrounding(from)
            |> Enum.into(%{})
            |> order(direction)
          move_units(board, direction, opts[:unit].position, coords, [])
      end
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
