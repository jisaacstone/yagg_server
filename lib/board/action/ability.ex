alias Yagg.Board
alias Yagg.Unit
alias Yagg.Event
alias Yagg.Table.Player
alias Yagg.Board.State
alias Yagg.Board.Hand
alias Yagg.Board.Action

defmodule Action.Ability do
  @behaviour Action

  @callback resolve(Dict.t, Yagg.Board.t, keyword()) :: {Yagg.Board.t, [Yagg.Event.t]} | {:err, term}
  @callback description() :: String.t

  @enforce_keys [:name, :x, :y]
  defstruct [:params | @enforce_keys]
  alias __MODULE__

  @impl Action
  def resolve(data, %Board{state: :battle} = board, _position) do
    module = Module.safe_concat(Ability, String.capitalize(data.name))
    ability = struct!(module, data.params || [])
    coords = {data.x, data.y}
    case ability_at(board, ability, coords) do
      {:err, _} = err -> err
      unit -> module.resolve(ability, board, unit: unit, coords: coords)
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
      def resolve(board), do: resolve(%{}, board, [])
      def resolve(board, opts) when is_list(opts), do: resolve(%{}, board, opts)
    end
  end

  defp ability_at(board, %{__struct__: struct}, coords) do
    case board.grid[coords] do
      %Unit{ability: ^struct} = unit -> unit
      %Unit{} = u-> 
        IO.inspect([unit: u, s: struct])
        {:err, :unable}
      _ -> {:err, :empty}
    end
  end
end

defmodule Action.Ability.NOOP do
  @moduledoc "Does Nothing"
  use Action.Ability

  def resolve(_, board, _) do
    {board, []}
  end
end

defmodule Action.Ability.Selfdestruct do
  @moduledoc "Explode and destroy everything within 1 square radius"
  use Action.Ability

  def resolve(_selfdestuct, board, opts) do
    surround = Board.features_around(board, opts[:coords])
    Enum.reduce(surround, {board, []}, &killunit/2)
  end

  defp killunit({coords, %Unit{} = unit}, {board, events}) do
    {board, newevents} = Board.unit_death(board, unit, coords)
    {board, newevents ++ events}
  end
  defp killunit(_, state) do
    state
  end
end

defmodule Action.Ability.Concede do
  @moduledoc "Lose the game"
  use Action.Ability

  def resolve(_, board, opts) do
    {
      %{board | state: %State.Gameover{}},
      [Event.new(:gameover, %{winner: Player.opposite(opts[:unit].position)})]
    }
  end
end

defmodule Action.Ability.Rowburn do
  @moduledoc "Destory all units in the same row"
  use Action.Ability

  def resolve(_, board, opts) do
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

  def resolve(_, board, opts) do
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

  def resolve(_, board, opts) do
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
  def resolve(_, board, opts) do
    pos = opts[:unit].position
    newunit = %{opts[:unit] | triggers: %{}}
    Hand.add_unit(board, pos, newunit)
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
  def resolve(_, board, opts) do
    push_adjacent_units(board, opts[:coords])
  end

  def push_adjacent_units(board, coords) do
    Enum.reduce(
      Board.surrounding(coords),
      {board, []},
      fn({direction, coord}, b_e) ->
        case board.grid[coord] do
          %Unit{} = unit -> push_unit(b_e, direction, coord, unit)
          _ -> b_e
        end
      end
    )
  end

  def push_unit({board, events}, direction, coord, unit) do
    case Board.move(board, unit.position, coord, Board.next(direction, coord)) do
      {:err, :out_of_bounds} ->
        {newboard, newevents} = Board.unit_death(board, unit, coord)
        {newboard, events ++ newevents}
      {:err, _} -> {board, events}
      {:ok, newboard, newevents} -> {newboard, events ++ newevents}
    end
  end
end

defmodule Action.Ability.Manuver do
  @moduledoc """
  all adjacent friendly units move in the same direction,
  north, south, east, west
  """
  use Action.Ability, keys: [:direction]

  @impl Action.Ability
  def resolve(%{direction: sdirection}, board, opts) do
    case dir_from_str(sdirection) do
      {:err, _} = err -> err
      direction ->
        coords =
          Board.surrounding(opts[:coords])
          |> Enum.into(%{center: opts[:coords]})
          |> order(direction)
        move_units(board, direction, opts[:unit].position, coords, [])
    end
  end

  defp order(coord_map, direction) do
    # order matters because units might bump into things and each other
    {first, coord_map} = Map.pop(coord_map, direction)
    {second, coord_map} = Map.pop(coord_map, :center)
    [first, second | Map.values(coord_map)]
  end

  defp move_units(board, _direction, _position, [], events), do: {board, events}
  defp move_units(board, direction, position, [from | coords], events) do
    case Board.move(board, position, from, Board.next(direction, from)) do
      {:ok, newboard, newevents} ->
        move_units(newboard, direction, position, coords, events ++ newevents)
      _ -> move_units(board, direction, position, coords, events)
    end
  end

  defp dir_from_str(str) do
    str |> String.first() |> String.downcase() |> initial_to_dir()
  end

  defp initial_to_dir("n"), do: :north
  defp initial_to_dir("s"), do: :south
  defp initial_to_dir("e"), do: :east
  defp initial_to_dir("w"), do: :west
  defp initial_to_dir(_), do: {:err, :bad_direction}
end
