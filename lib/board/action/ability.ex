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

  @callback resolve(Board.t, keyword()) :: {Board.t, [Event.t]} | {:err, term}
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
          Grid.update(board, coord, fn(u) -> Unit.make_visible(u, [:ability, :name]) end)
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
      def description(), do: @moduledoc

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
  use Action.Ability, noreveal: :true

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

defmodule Action.Ability.Immobile do
  @moduledoc """
  Cannot move
  """
  use Action.Ability
  @impl Action.Ability
  def resolve(_, _), do: {:err, :immobile}
end
