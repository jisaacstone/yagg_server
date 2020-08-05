alias Yagg.Unit
alias Yagg.Board
alias Yagg.Event
alias Yagg.Board.Grid
alias Yagg.Board.Action.Ability

defmodule Unit.Catmover do
  @behaviour Unit
  @impl Unit
  def new(position) do
    Unit.new(
      position,
      :catmover,
      1,
      6,
      :nil,
      %{attack: Unit.Catmover.Jump}
    )
  end
end

defmodule Unit.Catmover.Jump do
  @moduledoc """
  If there is an empty square on the other side it will jump the enemy and kill it.
  """
  use Ability
  @impl Ability
  def resolve(board, opts) do
    next = IO.inspect(Grid.direction(opts[:from], opts[:to]) |> Grid.next(opts[:to]))
    case Grid.thing_at(board, next) do
      :nil -> IO.inspect(jump(board, next, opts))
      _ -> Board.do_battle(board, opts[:unit], opts[:opponent], opts[:from], opts[:to])
    end
  end

  defp jump(board, destination, opts) do
    {unit, grid} = Map.pop(board.grid, opts[:from])
    board = %{board | grid: Map.put_new(grid, destination, unit)}
    {board, events} = Board.unit_death(board, opts[:to]) 
    {
      board,
      [Event.ThingMoved.new(from: opts[:from], to: destination) | events]
    }
  end

end
