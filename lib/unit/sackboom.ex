alias Yagg.Unit
alias Yagg.Event
alias Yagg.Board
alias Yagg.Board.Grid
alias Yagg.Board.Action.Ability

defmodule Unit.Sackboom do
  @behaviour Unit
  @impl Unit
  def new(position) do
    Unit.new(
      position,
      :sackboom,
      3,
      6,
      :nil,
      %{move: Unit.Sackboom.Move.Zero}
    )
  end

  def move(board, coord, next_ability) do
    Grid.update(
      board,
      coord,
      fn(unit) -> %{unit | triggers: %{move: next_ability}} end
    )
  end

  def explode(board, unit, coord) do
    direction = Grid.cardinal(unit.position, :left)
    square = Grid.next(direction, coord)
    {board, events} = explode_thing(Grid.thing_at(board, square), board, square)
    Grid.update(
      board,
      coord,
      fn(unit) -> %{unit | triggers: %{move: Unit.Sackboom.Move.Zero}} end,
      events
    )
  end

  defp explode_thing(%Unit{} = unit, board, coord) do
    Board.unit_death(board, coord, unit: unit)
  end
  defp explode_thing(:block, board, coord) do
    {
      %{board | grid: Map.delete(board.grid, coord)},
      # bit of a hack, clean up someday?
      [Event.ThingMoved.new(from: coord, to: :offscreen)]
    }
  end
  defp explode_thing(_, board, _), do: {board, []}

end

defmodule Unit.Sackboom.Move do
  alias __MODULE__
  defmodule Zero do
    @moduledoc """
    Destroy everything in the left square on its third move
    """
    use Ability
    @impl Ability
    def resolve(board, opts) do
      Unit.Sackboom.move(board, opts[:to], Move.One)
    end
  end

  defmodule One do
    @moduledoc """
    Destroy everything in the left square on its second move
    """
    use Ability
    @impl Ability
    def resolve(board, opts) do
      Unit.Sackboom.move(board, opts[:to], Move.Two)
    end
  end

  defmodule Two do
    @moduledoc """
    Destroy everything in the left square on its next move
    """
    use Ability
    @impl Ability
    def resolve(board, opts) do
      Unit.Sackboom.explode(board, opts[:unit], opts[:to])
    end
  end
end
