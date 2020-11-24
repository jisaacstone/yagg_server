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
  Will not attack but jump over and destroy an enemy if there is an empty square on the opposite side.
  """
  use Ability
  @impl Ability
  def resolve(board, opts) do
    next = Grid.direction(opts[:from], opts[:to]) |> Grid.next(opts[:to])
    maybe_jump(board, next, Grid.thing_at(board, next), opts)
  end

  def maybe_jump(board, next, :nil, opts) do
    jump(board, next, opts)
  end
  def maybe_jump(board, _, _, opts) do
    Board.do_battle(board, opts[:unit], opts[:opponent], opts[:from], opts[:to])
  end

  defp jump(board, destination, opts) do
    {unit, grid} = Map.pop(board.grid, opts[:from])
    board = %{board | grid: Map.put(grid, destination, unit)}
    {board, events} = Board.unit_death(board, opts[:to]) 
    {
      board,
      [Event.ThingMoved.new(from: opts[:from], to: destination) | events]
    }
  end

end
