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
  @callback reveal?() :: boolean

  @enforce_keys [:x, :y]
  defstruct @enforce_keys

  @impl Action
  def resolve(data, %Board{state: :battle} = board, position) do
    coord = {data.x, data.y}
    case ability_at(board, coord, position) do
      {:err, _} = err -> err
      {:ok, unit} ->
        {board, e1} = if unit.ability.reveal?() and not Unit.visible?(unit, :ability) do
          Grid.update(board, coord, fn(u) -> Unit.make_visible(u, :ability) end)
        else
          {board, []}
        end
        {board, e2} = unit.ability.resolve(board, unit: unit, coords: coord)
        {board, e1 ++ e2}
    end
  end

  def describe(:nil), do: :nil
  def describe(action) do
    name = Module.split(action) |> Enum.reverse() |> hd() |> String.downcase()
    %{name: name, args: action.__struct__(), description: action.description()}
  end

  defmacro __using__(opts) do
    struct = Keyword.get(opts, :keys, [])
    reveal = not(Keyword.get(opts, :noreveal, :false)) # by default using an ability reveals it
    quote do
      @behaviour Action.Ability

      @enforce_keys unquote(struct)
      defstruct @enforce_keys

      def resolve(%Board{} = board), do: resolve(board, [])

      @impl Action.Ability
      def description(), do: @moduledoc <> ". Reveals: #{reveal?()}"

      @impl Action.Ability
      def reveal?(), do: unquote(reveal)
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
    {grid, events} = reveal_units(board)
    {
      %{board | state: %State.Gameover{}, grid: grid},
      [Event.Gameover.new(winner: Player.opposite(opts[:unit].position)) | events]
    }
  end

  defp reveal_units(%{grid: grid}) do
    Enum.reduce(grid, {%{}, []}, &reveal/2)
  end

  defp reveal({{x, y}, %Unit{} = unit}, {grid, events}) do
    event = Event.NewUnit.new(Player.opposite(unit.position), x: x, y: y, unit: unit)
    grid = Map.put_new(grid, {x, y}, %{unit | visible: :all})
    {grid, [event | events]}
  end
  defp reveal({k, v}, {grid, events}) do
    grid = Map.put_new(grid, k, v)
    {grid, events}
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

  defp burn_unit({{x, y}, %Unit{}}, {board, events}, y) do
    {board, newevents} = Board.unit_death(board, {x, y})
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

  defp burn_unit({{x, y}, %Unit{}}, {board, events}, x) do
    {board, newevents} = Board.unit_death(board, {x, y})
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
      {%Unit{}, coords} -> Board.unit_death(board, coords)
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
    case board.grid[coord] do
      %Unit{} = unit ->
        copy = %{unit | position: pos}
        Hand.add_unit(board, pos, copy)
      _ -> {board, []}
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
        {newboard, newevents} = Board.unit_death(board, coord)
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
    {board, e1} = case board.grid[opts[:coords]] do
      :nil -> {board, []}
      ^unit -> Board.unit_death(board, opts[:coords])
    end
    newunit = %{opts[:unit] | attack: unit.attack + 2, defense: unit.defense + 2}
    {board, e2} = Hand.add_unit(board, unit.position, newunit)
    {board, e1 ++ e2}
  end
end

