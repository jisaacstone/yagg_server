alias Yagg.Unit
alias Yagg.Event

defmodule Yagg.Board do
  alias __MODULE__
  alias Board.State

  @enforce_keys [:grid, :hands, :state]
  defstruct @enforce_keys

  @type t :: %Board{
    grid: map(),
    hands: map(),
    state: State.t,
  }

  defimpl Poison.Encoder, for: Board do
    def encode(%Board{grid: grid} = board, options) do
      encodeable = grid
        |> Map.to_list()
        |> Map.new(fn({{x, y}, f}) -> {"#{x},#{y}", encode_feature(f)} end)
      Poison.Encoder.Map.encode(
        %{state: board.state,
          grid: encodeable},
        options
      )
    end

    defp encode_feature(%Unit{position: pos}), do: %{kind: :unit, player: pos}
    defp encode_feature(other), do: other
  end

  def new() do
    %Board{
      grid: %{{1, 2} => :water, {4, 2} => :water},
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

  def setup(board) do
    events = Enum.map(board.grid, fn({{x, y}, feature}) -> Event.new(:feature, %{x: x, y: y, feature: feature}) end)
    {board, events} = Enum.reduce(
      [:north, :south],
      {board, events},
      fn(player, {board, notifications}) ->
        {hand, notif} = create_hand(player, notifications)
        {%{board | hands: Map.put(board.hands, player, hand)}, notif}
      end
    )
    {
      board,
      [Event.new(:game_started) | events]
    }
  end
  ## Private

  defp create_hand(position, notifications) do
    {_, hand, notif} = Enum.reduce(
      Unit.starting_units(position),
      {0, %{}, notifications},
      fn (unit, {i, h, n}) ->
        {
          i + 1,
          Map.put_new(h, i, {unit, :nil}),
          [Event.new(unit.position, :new_hand, %{unit: unit, index: i}) | n]
        }
      end
    )
    {hand, notif}
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
