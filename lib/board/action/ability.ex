alias Yagg.Board
alias Yagg.Unit
alias Yagg.Event
alias Yagg.Table.Player
alias Yagg.Board.State
alias Yagg.Board.Hand
alias Yagg.Board.Grid
alias Yagg.Board.Action

defmodule Action.Ability do
  @behaviour Action

  @callback resolve(Yagg.Board.t, keyword()) :: {Yagg.Board.t, [Yagg.Event.t]} | {:err, term}
  @callback description() :: String.t

  @enforce_keys [:x, :y]
  defstruct @enforce_keys

  @impl Action
  def resolve(data, %Board{state: :battle} = board, position) do
    coords = {data.x, data.y}
    case ability_at(board, coords, position) do
      {:err, _} = err -> err
      {:ok, unit} -> unit.ability.resolve(board, unit: unit, coords: coords)
    end
  end

  def describe(:nil), do: :nil
  def describe(action) do
    name = Module.split(action) |> Enum.reverse() |> hd() |> String.downcase()
    %{name: name, args: action.__struct__(), description: action.description()}
  end

  defmacro __using__(opts) do
    struct = Keyword.get(opts, :keys, [])
    quote do
      @behaviour Action.Ability

      @impl Action.Ability
      def description(), do: @moduledoc
      @enforce_keys unquote(struct)
      defstruct @enforce_keys
      def resolve(%Board{} = board), do: resolve(board, [])
    end
  end

  defp ability_at(board, coords, position) do
    case board.grid[coords] do
      %Unit{ability: :nil} -> {:err, :noable}
      %Unit{position: ^position} = unit -> {:ok, unit}
      %Unit{} -> {:err, :unowned}
      _ -> {:err, :nounit}
    end
  end
end

defmodule Action.Ability.NOOP do
  @moduledoc "Does Nothing"
  use Action.Ability

  def resolve(board, _) do
    {board, []}
  end
end

defmodule Action.Ability.Concede do
  @moduledoc "Lose the game"
  use Action.Ability

  def resolve(board, opts) do
    {
      %{board | state: %State.Gameover{}},
      [Event.Gameover.new(winner: Player.opposite(opts[:unit].position))]
    }
  end
end

defmodule Action.Ability.Rowburn do
  @moduledoc "Destory all units in the same row"
  use Action.Ability

  def resolve(board, opts) do
    {_, y} = opts[:coords]
    Enum.reduce(
      board.grid,
      {board, []},
      &burn_unit(&1, &2, y)
    )
  end

  defp burn_unit({{x, y}, %Unit{} = unit}, {board, events}, y) do
    {board, newevents} = Board.unit_death(board, unit, {x, y})
    {board, newevents ++ events}
  end
  defp burn_unit(_, acc, _) do
    acc
  end
end

defmodule Action.Ability.Colburn do
  @moduledoc "Destory all units in the same column"
  use Action.Ability

  def resolve(board, opts) do
    {x, _} = opts[:coords]
    Enum.reduce(
      board.grid,
      {board, []},
      &burn_unit(&1, &2, x)
    )
  end

  defp burn_unit({{x, y}, %Unit{} = unit}, {board, events}, x) do
    {board, newevents} = Board.unit_death(board, unit, {x, y})
    {board, newevents ++ events}
  end
  defp burn_unit(_, acc, _) do
    acc
  end
end

defmodule Action.Ability.Poisonblade do
  @moduledoc "Poisons any units that touch it"
  use Action.Ability

  def resolve(board, opts) do
    case opts[:opponent] do
      :nil -> {board, []}
      {unit, coords} -> Board.unit_death(board, unit, coords)
    end
  end
end

defmodule Action.Ability.Secondwind do
  @moduledoc "goes back into hand"
  use Action.Ability

  @impl Action.Ability
  def resolve(board, opts) do
    pos = opts[:unit].position
    newunit = %{opts[:unit] | triggers: %{}}
    Hand.add_unit(board, pos, newunit)
  end
end

defmodule Action.Ability.Copyleft do
  @moduledoc "copy the unit to the left of this unit, put the copy in your hand"
  use Action.Ability

  @impl Action.Ability
  def resolve(board, opts) do
    pos = opts[:unit].position
    coord = Grid.cardinal(pos, :left) |> Grid.next(opts[:coords])
    IO.inspect(opts: opts, coord: coord)
    case board.grid[coord] do
      %Unit{} = unit ->
        copy = %{unit | position: pos}
        Hand.add_unit(board, pos, copy)
      _ -> {board, []}
    end
  end
end

defmodule Action.Ability.Duplicate do
  @moduledoc """
  leave behind an inferior copy
  """
  use Action.Ability

  @impl Action.Ability
  def resolve(%Board{} = board, opts) do
    unit = opts[:unit]
    {x, y} = opts[:from]
    copy = %{
      opts[:unit] |
      attack: unit.attack - 2,
      defense: unit.defense - 2
    }
    if copy.attack < 0 or copy.defense < 0 do
      { board, [] }
    else 
      grid = Map.put(board.grid, opts[:from], copy)
      {
        %{board | grid: grid},
        [
          Event.UnitPlaced.new(player: unit.position, x: x, y: y),
          Event.NewUnit.new(unit.position, x: x, y: y, unit: copy)
        ]
      }
    end
  end
end

defmodule Action.Ability.Push do
  @moduledoc """
  push surrounding units back one square
  the push is as if the owner had moved the unit (will attack if new square is occupied)
  units at the edge are pushed off the board (and die)
  """
  use Action.Ability

  @impl Action.Ability
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
        {newboard, newevents} = Board.unit_death(board, unit, coord)
        {newboard, events ++ newevents}
      {:err, _} -> {board, events}
      {newboard, newevents} -> {newboard, events ++ newevents}
    end
  end

  defp push_block({board, events}, direction, coord) do
    case Board.push_block(board, coord, Grid.next(direction, coord)) do
      {:err, _} -> {board, events}
      {newboard, newevents} -> {newboard, events ++ newevents}
    end
  end
end

defmodule Action.Ability.Upgrade do
  @moduledoc """
  Return to your hand and gain +2 attack and +2 defense
  """

  use Action.Ability
  @impl Action.Ability
  def resolve(%Board{} = board, opts) do
    unit = opts[:unit]
    {board, e1} = Board.unit_death(board, unit, opts[:coords])
    newunit = %{opts[:unit] | attack: unit.attack + 2, defense: unit.defense + 2}
    {board, e2} = Hand.add_unit(board, unit.position, newunit)
    {board, e1 ++ e2}
  end
end

