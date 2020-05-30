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
      %Unit{} -> {:err, :unable}
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
