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
      defense: 4,
      ability: Unit.Pushie.Push
    )
  end

  defmodule Push do
    @moduledoc """
    Push adjacent units one square away or off the board
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
          event = Event.ThingMoved.new(from: coord, to: :offscreen, direction: direction) 
          {newboard, events ++ [event | newevents]}
        {:err, _} -> {board, events}
        {newboard, newevents} -> {newboard, events ++ newevents}
      end
    end

    defp push_block({board, events}, direction, coord) do
      next = Grid.next(direction, coord)
      case Board.push_block(board, coord, next) do
        {:err, :out_of_bounds} ->
          board = %{board | grid: Map.delete(board.grid, coord)}
          event = Event.ThingMoved.new(from: coord, to: :offscreen, direction: direction) 
          {board, [event | events]}
        {:err, _} -> {board, events}
        {newboard, newevents} -> {newboard, events ++ newevents}
      end
    end
  end
end
