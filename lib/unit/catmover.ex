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
  use Ability.BeforeAttack
  @impl Ability.BeforeAttack
  def before_attack(board, data) do
    next = Grid.direction(data.from, data.to) |> Grid.next(data.to)
    maybe_jump(board, next, Grid.thing_at(board, next), data)
  end

  def maybe_jump(board, next, :nil, data) do
    jump(board, next, data)
  end
  def maybe_jump(board, _, _, data) do
    Board.do_battle(board, data.unit, data.opponent, data.from, data.to)
  end

  defp jump(board, destination, %{from: from, to: to}) do
    {unit, grid} = Map.pop(board.grid, from)
    board = %{board | grid: Map.put(grid, destination, unit)}
    {board, events} = Board.unit_death(board, to) 
    {
      board,
      [Event.ThingMoved.new(from: from, to: destination) | events]
    }
  end
end
