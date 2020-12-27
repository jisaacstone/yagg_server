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

defmodule Action.Ability.OnDeath do
  alias __MODULE__

  @enforce_keys [:coord, :unit]
  defstruct [:opponent | @enforce_keys]

  @type t :: %OnDeath{
    coord: Grid.coord,
    unit: Unit.t,
    opponent: :nil | Unit.t
  }

  @callback on_death(Board.t, t) :: {Board.t, [Event.t]} | {:err, atom}

  defmacro __using__(opts) do
    quote do
      require Action.Ability
      Action.Ability.__using__(unquote(opts))
      @behaviour Action.Ability.OnDeath
      def resolve(board, opts) do
        {coord, opts} = Keyword.pop!(opts, :coords)
        {unit, opts} = Keyword.pop!(opts, :unit)
        {opponent, opts} = Keyword.pop(opts, :opponent)
        data = %OnDeath{coord: coord, unit: unit, opponent: opponent}
        on_death(board, data)
      end
    end
  end
end

defmodule Action.Ability.AfterMove do
  alias __MODULE__

  @enforce_keys [:from, :to, :unit]
  defstruct @enforce_keys

  @type t :: %AfterMove{
    from: Grid.coord,
    to: Grid.coord,
    unit: Unit.t
  }

  @callback after_move(Board.t, t) :: {Board.t, [Event.t]} | {:err, atom}

  defmacro __using__(opts) do
    quote do
      require Action.Ability
      Action.Ability.__using__(unquote(opts))
      @behaviour Action.Ability.AfterMove
      def resolve(board, opts) do
        {from, opts} = Keyword.pop!(opts, :from)
        {to, opts} = Keyword.pop!(opts, :to)
        {unit, opts} = Keyword.pop!(opts, :unit)
        data = %AfterMove{from: from, to: to, unit: unit}
        after_move(board, data)
      end
    end
  end
end

defmodule Action.Ability.BeforeAttack do
  alias __MODULE__

  @enforce_keys [:from, :to, :unit, :opponent]
  defstruct @enforce_keys

  @type t :: %BeforeAttack{
    from: Grid.coord,
    to: Grid.coord,
    unit: Unit.t,
    opponent: Unit.t
  }

  @callback before_attack(Board.t, t) :: {Board.t, [Event.t]} | {:err, atom}

  defmacro __using__(opts) do
    quote do
      require Action.Ability
      Action.Ability.__using__(unquote(opts))
      @behaviour Action.Ability.BeforeAttack
      def resolve(board, opts) do
        {from, opts} = Keyword.pop!(opts, :from)
        {to, opts} = Keyword.pop!(opts, :to)
        {unit, opts} = Keyword.pop!(opts, :unit)
        {opponent, opts} = Keyword.pop!(opts, :opponent)
        data = %BeforeAttack{from: from, to: to, unit: unit, opponent: opponent}
        before_attack(board, data)
      end
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

  def resolve(%{state: %State.Gameover{winner: winner}} = board, opts) do
    case Player.opposite(opts[:unit].position) do
      ^winner -> {board, []}
      _ -> {%{board | state: Map.put(board.state, :winner, :draw)}, []}
    end
  end
  def resolve(board, opts) do
    {grid, events} = reveal_units(board)
    winner = Player.opposite(opts[:unit].position)
    board = %{board | state: %State.Gameover{winner: winner}, grid: grid}
    {board, events}
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

defmodule Action.Ability.Immobile do
  @moduledoc """
  Cannot move
  """
  use Action.Ability
  @impl Action.Ability
  def resolve(_, _), do: {:err, :immobile}
end
