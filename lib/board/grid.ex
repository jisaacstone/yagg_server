alias Yagg.Board
alias Yagg.Unit
alias Yagg.Event

defmodule Yagg.Board.Grid do
  @type coord() :: {0..5, 0..5}
  @type terrain :: :water | Unit.t
  @type t :: %{coord => terrain}

  @doc """
  Returns what is at the coords, :nil if nothing is there, and :out_of_bounds if it is out of the grid
  """
  @spec thing_at(Board.t, coord) :: :nil | :out_of_bounds | terrain
  def thing_at(_, {x, y}) when x < 0 or y < 0, do: :out_of_bounds
  def thing_at(_, {x, y}) when x >= 5 or y >= 5, do: :out_of_bounds
  def thing_at(board, coords), do: board.grid[coords]

  @doc """
  direction to coord math
  """
  @spec next(Board.direction, coord) :: coord
  def next(:west, {x, y}), do: {x - 1, y}
  def next(:east, {x, y}), do: {x + 1, y}
  def next(:north, {x, y}), do: {x, y + 1}
  def next(:south, {x, y}), do: {x, y - 1}

  @doc """
  Takes two points and retires the direction from the first to the second
  errors if the points are not on a line.
  """
  @spec direction(coord, coord) :: Board.direction
  def direction({x1, y}, {x2, y}) when x1 < x2, do: :east
  def direction({x1, y}, {x2, y}) when x1 > x2, do: :west
  def direction({x, y1}, {x, y2}) when y1 > y2, do: :south
  def direction({x, y1}, {x, y2}) when y1 < y2, do: :north
  def direction(_, _), do: {:err, :not_on_line}

  @doc """
  all adjacent squares (add, sub 1 for x, y)
  returns {direction, coord} tuples
  """
  @spec surrounding(coord) :: [{Board.direction, coord}]
  def surrounding(coord) do
    Enum.map(
      [:north, :south, :east, :west],
      fn(dir) -> {dir, next(dir, coord)} end
    )
  end

  def update(%Board{} = board, {x, y} = coord, updater, events \\ []) do
    case board.grid[coord] do
      %Unit{} = unit ->
        updated = updater.(unit)
        {
          %{board | grid: Map.put(board.grid, coord, updated)},
          [Event.UnitChanged.new(unit.position, x: x, y: y, unit: updated) | events]
        }
      _other -> {board, events}
    end
  end
end
