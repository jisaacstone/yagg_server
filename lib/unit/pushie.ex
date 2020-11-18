alias Yagg.Unit
alias Yagg.Event
alias Yagg.Board
alias Yagg.Board.Grid
alias Yagg.Board.Action.Ability

defmodule Unit.Pushie do
  @behaviour Unit
  @impl Unit
  def new(position) do
    Unit.new(
      position: position,
      name: :pushie,
      attack: 5,
      defense: 0,
      ability: Unit.Pushie.Push
    )
  end

  defmodule Push do
    @moduledoc """
    surrounding units move one square back
    units at the edge are pushed off the board and die
    """
    use Ability

    @impl Ability
    def resolve(board, opts) do
      push_adjacent_units(board, opts[:coords])
    end

    defp push_adjacent_units(board, coords) do
      Enum.reduce(
        Grid.surrounding(coords),
        {board, []},
        fn({direction, coord}, b_e) ->
          case board.grid[coord] do
            %Unit{} = unit -> push_unit(b_e, direction, coord, unit)
            :block -> push_block(b_e, direction, coord)
            _ -> b_e
          end
        end
      )
    end

    defp push_unit({board, events}, direction, coord, unit) do
      case Board.move(board, unit.position, coord, Grid.next(direction, coord)) do
        {:err, :out_of_bounds} ->
          {newboard, newevents} = Board.unit_death(board, coord)
          {newboard, events ++ newevents}
        {:err, _} -> {board, events}
        {newboard, newevents} -> {newboard, events ++ newevents}
      end
    end

    defp push_block({board, events}, direction, {x, y}) do
      case Board.push_block(board, {x, y}, Grid.next(direction, {x, y})) do
        {:err, :out_of_bounds} ->
          board = %{board | grid: Map.delete(board.grid, {x, y})}
          events = [Event.ThingGone.new(x: x, y: y) | events]
          {board, events}
        {:err, _} -> {board, events}
        {newboard, newevents} -> {newboard, events ++ newevents}
      end
    end
  end
end
