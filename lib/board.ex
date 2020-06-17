alias Yagg.Unit
alias Yagg.Event
alias Yagg.Table.Player
alias Yagg.Board.Hand
alias Yagg.Board.Configuration

defmodule Yagg.Board do
  alias __MODULE__
  alias Board.State

  @enforce_keys [:grid, :hands, :state]
  defstruct @enforce_keys

  @type coord() :: {0..5, 0..5}
  @type terrain :: :water | Unit.t

  @type t :: %Board{
    grid: %{coord() => terrain},
    hands: %{Player.position() => Hand.t},
    state: State.t,
  }

  defimpl Poison.Encoder, for: Board do
    def encode(%Board{grid: grid} = board, options) do
      encodeable = grid
        |> Map.to_list()
        |> Map.new(fn({{x, y}, f}) -> {"#{x},#{y}", encode_feature(f)} end)
      map = case board.state do
        %{ready: ready} ->
            %{ready: ready, state: board.state.__struct__ |> Module.split() |> Enum.reverse() |> hd()}
        state when is_atom(state) ->
          %{state: state}
      end
      Poison.Encoder.Map.encode(
        Map.put_new(map, :grid, encodeable),
        options
      )
    end

    defp encode_feature(%Unit{position: pos}), do: %{kind: :unit, player: pos}
    defp encode_feature(other), do: other
  end

  def new() do
    %Board{
      grid: %{},
      hands: %{north: %{}, south: %{}},
      state: %State.Placement{},
    }
  end

  def assign(board, position, hand_index, coords) do
    if can_place?(position, coords) do
      case hand_assign(board.hands[position], hand_index, coords) do
        {:err, _} = err -> err
        hand -> {:ok, %{board | hands: Map.put(board.hands, position, hand)}}
      end
    else
      {:err, :illegal_square}
    end
  end

  defp hand_assign(hand, index, coords) do
    case hand[index] do
      :nil -> {:err, :invalid_index}
      {unit, _} ->
        if Enum.any?(hand, fn({_, {_, ^coords}}) -> :true; (_) -> :false end) do
          {:err, :occupied}
        else 
          %{hand | index => {unit, coords}}
        end
    end
  end

  def place!(%Board{} = board, %Unit{} = unit, coords) do
    case place(board, unit, coords) do
      {:ok, board} -> board
      err -> throw(err)
    end
  end
  def place(%Board{grid: grid} = board, %Unit{} = unit, coords) do
    case grid[coords] do
      :nil ->
        unless can_place?(unit.position, coords) do
          {:err, :illegal_square}
        else
          {:ok, %{board | grid: Map.put_new(grid, coords, unit)}}
        end
      _something -> {:err, :occupied}
    end
  end

  defp can_place?(:north, {_, y}) when y in 3..4, do: :true
  defp can_place?(:north, _), do: :false
  defp can_place?(:south, {_, y}) when y in 0..1, do: :true
  defp can_place?(:south, _), do: :false

  def units(:nil, _), do: {:ok, %{grid: [], hand: []}}
  def units(board, position) do
    ongrid = Enum.reduce(
      board.grid,
      [],
      fn
        ({{x, y}, %Unit{position: ^position} = unit}, units) ->
          [%{x: x, y: y, unit: unit} | units]
        (_, units) ->
          units
      end
    )
    hand = Enum.map(board.hands[position],
      fn({i, {u, p}}) -> {i, %{unit: u, assigned: p}} end) |> Enum.into(%{})
    {:ok, %{grid: ongrid, hand: hand}}
  end

  def move(%Board{} = board, position, from, to) do
    case board.grid[from] do
      %Unit{position: ^position} = unit ->
        unless can_move?(from, to) do
          {:err, :illegal}
        else
          case thing_at(board, to) do
            :out_of_bounds -> {:err, :out_of_bounds}
            :water -> {:err, :illegal}
            :block -> 
              push_block(board, from, to)
            :nil -> 
              do_move(board, from, to)
            feature -> 
              do_battle(board, unit, feature, from, to)
          end
        end
      {%Unit{}, _coords} -> {:err, :nocontrol}
      :nil -> {:err, :empty}
      _ -> {:err, :illegal}
    end
  end

  @doc """
  Unit dies as {x, y}. Returns new board and events
  """
  def unit_death(board, unit, {x, y}, meta \\ []) do
    board = %{board | grid: Map.delete(board.grid, {x, y})}
    opts = [{:unit, unit}, {:coords, {x, y}} | meta]
    {board, events} = Unit.trigger_module(unit, :death).resolve(board, opts)
    {
      board,
      [Event.UnitDied.new(x: x, y: y) | events]
    }
  end

  @doc """
  Returns what is at the coords, :nil if nothing is there, and :out_of_bounds if it is out of the grid
  """
  def thing_at(_, {x, y}) when x < 0 or y < 0, do: :out_of_bounds
  def thing_at(_, {x, y}) when x >= 5 or y >= 5, do: :out_of_bounds
  def thing_at(board, coords), do: board.grid[coords]

  def setup(board), do: setup(board, Configuration.Default)
  def setup(board, configuration) do
    {board, events} = add_features(board, [], configuration.terrain())
    {board, events} = Enum.reduce(
      [:north, :south],
      {board, events},
      fn(player, {board, notifications}) ->
        {hand, notif} = Hand.new(player, notifications, configuration)
        {%{board | hands: Map.put(board.hands, player, hand)}, notif}
      end
    )
    {
      board,
      [Event.GameStarted.new() | events]
    }
  end

  @doc """
  direction to coord math
  """
  def next(:west, {x, y}), do: {x - 1, y}
  def next(:east, {x, y}), do: {x + 1, y}
  def next(:north, {x, y}), do: {x, y + 1}
  def next(:south, {x, y}), do: {x, y - 1}

  @doc """
  Takes two points and retires the direction from the first to the second
  errors if the points are not on a line.
  """
  def direction({x1, y}, {x2, y}) when x1 < x2, do: :east
  def direction({x1, y}, {x2, y}) when x1 > x2, do: :west
  def direction({x, y1}, {x, y2}) when y1 > y2, do: :south
  def direction({x, y1}, {x, y2}) when y1 < y2, do: :north
  def direction(_, _), do: {:err, :not_on_line}

  @doc """
  all adjacent squares (add, sub 1 for x, y)
  returns {direction, coord} tuples
  """
  def surrounding(coords) do
    Enum.map(
      [:north, :south, :east, :west],
      fn(dir) -> {dir, next(dir, coords)} end
    )
  end

  ## Private
  
  defp add_features(board, events, []), do: {board, events}
  defp add_features(board, events, [{{x, y}, feature} | features]) do
    board = %{board | grid: Map.put_new(board.grid, {x, y}, feature)}
    events = [Event.Feature.new(x: x, y: y, feature: feature) | events]
    add_features(board, events, features)
  end

  defp can_move?({x, y}, {to_x, to_y}) do
    Enum.sort([abs(x - to_x), abs(y - to_y)]) == [0, 1]
  end

  defp do_move(%Board{} = board, from, to, opts \\ []) do
    {unit, grid} = Map.pop(board.grid, from)
    grid = Map.put_new(grid, to, unit)
    board = %{board | grid: grid}
    opts = [{:from, from}, {:to, to}, {:unit, unit} | opts]
    {board, events} = Unit.trigger_module(unit, :move).resolve(board, opts)
    {
      board,
      [Event.UnitMoved.new(from: from, to: to) | events]
    }
  end

  defp do_battle(_, %Unit{position: pos}, %Unit{position: pos}, _, _) do
    {:err, :noselfattack}
  end
  defp do_battle(board, unit, opponent, from, to) do
    cond do
      unit.attack > opponent.defense ->
        {board, e1} = unit_death(board, opponent, to, opponent: {unit, from})
        {board, e2} = do_move(board, from, to)
        {board, e1 ++ e2}
      unit.attack == opponent.defense ->
        # not currently possible?
        {board, e1} = unit_death(board, unit, from)
        {board, e2} = unit_death(board, opponent, to)
        {board, e1 ++ e2}
      unit.attack < opponent.defense ->
        {board, events} = unit_death(board, unit, from, opponent: {opponent, to}, attacking: :true)
        {board, events}
    end
  end

  def push_block(board, from, to) do
    dir = direction(from, to)
    square = next(dir, to)
    case board.grid[square] do
      :nil -> 
        {board, events1} = do_move(board, to, square)
        {board, events2} = do_move(board, from, to)
        {board, events1 ++ events2}
      _ ->
        {:err, :occupied}
    end
  end
end
