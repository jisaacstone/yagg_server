alias Yagg.Unit
alias Yagg.Board
alias Yagg.Board.Grid
alias Yagg.Board.Action.Ability

defmodule Unit.Spikeder do
  @behaviour Unit
  @impl Unit
  def new(position) do
    Unit.new(
      position,
      :spikeder,
      3,
      2,
      :nil,
      %{
        death: Ability.Poisonblade,
        move: Unit.Spikeder.Slide,
      }
    )
  end

  defmodule Slide do
    @moduledoc """
    Keeps moving until it hits something
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
end
