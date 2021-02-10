alias Yagg.Unit
alias Yagg.Event
alias Yagg.Table.Player
alias Yagg.Board
alias Yagg.Board.Grid
alias Yagg.Board.Hand

defmodule Unit.Ability do
  @behaviour Board.Action

  @callback resolve(Board.t, keyword()) :: {Board.t, [Event.t]} | {:err, term}
  @callback description() :: String.t
  @callback reveal?() :: boolean

  @enforce_keys [:x, :y]
  defstruct @enforce_keys

  @impl Board.Action
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
      @behaviour Unit.Ability

      @enforce_keys unquote(struct)
      defstruct @enforce_keys

      def resolve(%Board{} = board), do: resolve(board, [])

      @impl Unit.Ability
      def description(), do: @moduledoc

      @impl Unit.Ability
      def reveal?(), do: unquote(reveal)
    end
  end

  @spec reveal(Grid.coord, Board.t, Player.position, [Event.t]) :: {Board.t, [Event.t]}
  def reveal({x, y}, board, position, events \\ []) do
    enemy = Player.opposite(position)
    {board, events} = case board.grid[{x, y}] do
      %Unit{visible: :all} -> {board, events}
      %Unit{position: ^enemy} ->
        Grid.update(
          board,
          {x, y},
          fn(u) -> %{u | visible: :all} end,
          [Event.AbilityUsed.new(position, type: :scan, x: x, y: y) | events]
        )
      _ -> {board, events}
    end
    {board, events}
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

defmodule Unit.Ability.NOOP do
  @moduledoc "Does Nothing"
  use Unit.Ability, noreveal: :true

  def resolve(board, _) do
    {board, []}
  end
end

defmodule Unit.Ability.Secondwind do
  @moduledoc "goes back into hand"
  use Unit.Ability

  @impl Unit.Ability
  def resolve(board, opts) do
    pos = opts[:unit].position
    newunit = %{opts[:unit] | triggers: %{}}
    Hand.add_unit(board, pos, newunit)
  end
end
