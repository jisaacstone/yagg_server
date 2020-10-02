alias Yagg.Board
alias Yagg.Unit
alias Yagg.Event
alias Yagg.Table.Player

defmodule Yagg.Board.Grid do
  @type coord() :: {0..5, 0..5}
  @type terrain :: :water | :block | Unit.t
  @type relative :: :left | :right | :front | :back
  @type t :: %{coord => terrain}

  defguard is_relative(dir) when dir == :left or dir == :right or dir == :front or dir == :back
  defguard is_cardinal(dir) when dir == :nort or dir == :south or dir == :east or dir == :west
  defguard is_coord(c) when is_tuple(c) and is_integer(elem(c, 0)) and is_integer(elem(c, 1))

  @doc """
  Returns what is at the coords, :nil if nothing is there, and :out_of_bounds if it is out of the grid
  """
  @spec thing_at(Board.t, coord) :: :nil | :out_of_bounds | terrain
  def thing_at(_, {x, y}) when x < 0 or y < 0, do: :out_of_bounds
  def thing_at(%{dimensions: {w, h}}, {x, y}) when x >= w or y >= h, do: :out_of_bounds
  def thing_at(board, coords), do: board.grid[coords]

  @spec thing_in_direction(Board.t, coord, {Player.position, relative} | Board.direction | {coord, coord}) :: :nil | :out_of_bounds | terrain
  def thing_in_direction(board, coord, {position, direction}) when is_relative(direction) do
    thing_in_direction(board, coord, cardinal(position, direction))
  end
  def thing_in_direction(board, coord, direction) when is_cardinal(direction) do
    thing_at(board, next(direction, coord))
  end
  def thing_in_direction(board, coord, {from, to}) when is_coord(from) and is_coord(to) do
    thing_in_direction(board, coord, direction(from, to))
  end

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

  @doc """
  transfer directional (:left, :right) into cardinal (:east, :west)
  """
  @spec cardinal(Player.position, relative) :: Board.direction
  def cardinal(:north, :left), do: :east
  def cardinal(:south, :left), do: :west
  def cardinal(:north, :right), do: :west
  def cardinal(:south, :right), do: :east
  def cardinal(:north, :front), do: :south
  def cardinal(:south, :front), do: :north
  def cardinal(position, :back), do: position

  @doc """
  in-place update of unit at coord
  """
  @spec update(Board.t, coord, (Unit.t -> Unit.t), [Event.t]) :: {Board.t, [Event.t]}
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

  @doc """
  Find next Unit in direction, starting at coord and skipping empty squares and water
  """
  @spec projectile(Board.t, coord, Board.direction) :: {coord, Unit.t} | :out_of_bounds
  def projectile(board, coord, direction) do
    IO.inspect([coord, direction])
    next_coord = next(direction, coord)
    case thing_at(board, next_coord) do
      %Unit{} = unit ->
        {next_coord, unit}
      atom when atom == :nil or atom == :water ->
        projectile(board, next_coord, direction)
      _other ->
        :out_of_bounds
    end
  end
end
