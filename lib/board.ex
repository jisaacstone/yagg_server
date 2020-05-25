alias Yagg.Unit
alias Yagg.Event
alias Yagg.Table.Player
alias Yagg.Board.Hand

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
      hand = hand_assign(board.hands[position], hand_index, coords)
      {:ok, %{board | hands: Map.put(board.hands, position, hand)}}
    else
      {:err, :illegal_square}
    end
  end

  defp hand_assign(hand, index, coords) do
    case hand[index] do
      :nil -> {:err, :invalid_index}
      {_unit, {_x, _y}} -> {:err, :already_assigned}
      {unit, :nil} -> %{hand | index => {unit, coords}}
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
        if can_place?(unit.position, coords) do
          {:ok, %{board | grid: Map.put_new(grid, coords, unit)}}
        else
          {:err, :illegal_square}
        end
      _something -> {:err, :occupied}
    end
  end

  defp can_place?(:north, {_, y}) when y in 3..4, do: :true
  defp can_place?(:north, _), do: :false
  defp can_place?(:south, {_, y}) when y in 0..1, do: :true
  defp can_place?(:south, _), do: :false

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

  def move(board, position, from, to) do
    case board.grid[from] do
      %Unit{position: ^position} = unit ->
        unless can_move?(from, to) do
          {:err, :illegal}
        else
          case board.grid[to] do
            :water -> {:err, :illegal}
            :nil -> 
              {board, events} = do_move(board, unit, from, to)
              {:ok, board, events}
            feature -> 
              do_battle(board, unit, feature, from, to)
          end
        end
      {%Unit{}, _coords} -> {:err, :nocontrol}
      :nil -> {:err, :empty}
      _ -> {:err, :illegal}
    end
  end

  def unit_death(board, unit, {x, y}, meta \\ []) do
    board = %{board | grid: Map.delete(board.grid, {x, y})}
    opts = [{:unit, unit}, {:coords, {x, y}} | meta]
    {board, events} = Unit.deathrattle(unit).resolve(board, opts)
    {
      board,
      [Event.new(:unit_died, %{x: x, y: y}) | events]
    }
  end

  @doc """
  Returnts a list of {coords, feature} tuple for any features within distance of {x, y}
  """
  def features_around(board, {x, y}, distance \\ 1) do
    # nested reduce gets all permutations
    Enum.reduce(
      x-distance..x+distance,
      [],
      fn(xa, features) ->
        Enum.reduce(
          y-distance..y+distance,
          features,
          fn(ya, features) ->
            case board.grid[{xa, ya}] do
              :nil -> features
              feature -> [{{xa, ya}, feature} | features]
            end
          end
        )
      end
    )
  end

  def setup(board), do: setup(board, Configuration.Default)
  def setup(board, configuration) do
    {board, events} = add_features(board, [], configuration.terrain())
    {board, events} = Enum.reduce(
      [:north, :south],
      {board, events},
      fn(player, {board, notifications}) ->
        {hand, notif} = Hand.new(configuration, player, notifications)
        {%{board | hands: Map.put(board.hands, player, hand)}, notif}
      end
    )
    {
      board,
      [Event.new(:game_started) | events]
    }
  end
  ## Private
  
  defp add_features(board, events, []), do: {board, events}
  defp add_features(board, events, [{{x, y}, feature} | features]) do
    board = %{board | grid: Map.put_new(board.grid, {x, y}, feature)}
    events = [Event.new(:feature, %{x: x, y: y, feature: feature}) | events]
    add_features(board, events, features)
  end

  defp can_move?({x, y}, {to_x, to_y}) do
    Enum.sort([abs(x - to_x), abs(y - to_y)]) == [0, 1]
  end

  defp do_move(board, unit, from, to) do
    grid = board.grid
      |> Map.delete(from)
      |> Map.put_new(to, unit)
    {
      %{board | grid: grid},
      [Event.new(:unit_moved, %{from: from, to: to})]
    }
  end

  defp do_battle(_, %Unit{position: pos}, %Unit{position: pos}, _, _) do
    {:err, :noselfattack}
  end
  defp do_battle(board, unit, opponent, from, to) do
    cond do
      unit.attack > opponent.defense ->
        {board, e1} = unit_death(board, opponent, to, opponent: {unit, from})
        {board, e2} = do_move(board, unit, from, to)
        {:ok, board, e1 ++ e2}
      unit.attack == opponent.defense ->
        # not currently possible?
        {board, e1} = unit_death(board, unit, from)
        {board, e2} = unit_death(board, opponent, to)
        {:ok, board, e1 ++ e2}
      unit.attack < opponent.defense ->
        {board, events} = unit_death(board, unit, from, opponent: {opponent, to}, attacking: :true)
        {:ok, board, events}
    end
  end
end
