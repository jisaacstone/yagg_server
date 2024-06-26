alias Yagg.Unit
alias Yagg.Board
alias Yagg.Board.Grid
alias Yagg.Unit.Ability

defmodule Unit.Ability.Slide do
  @moduledoc """
  Slides through empty squares
  """
  use Ability
  @impl Ability
  def resolve(board, opts) do
    if opts[:action] do
      {board, []}
    else 
      direction = Grid.direction(opts[:from], opts[:to])
      slide(board, opts[:unit], direction, opts[:to])
    end
  end

  defp slide(board, unit, direction, coord) do
    next_coord = Grid.next(direction, coord)
    # move will trigger another move, etc
    case Board.move(board, unit.position, coord, next_coord) do
      {:err, _} -> {board, []}
      {board, events} -> {board, events}
    end
  end
end
