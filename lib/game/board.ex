alias Yagg.Game.Unit
alias Yagg.Event

defmodule Yagg.Game.Board do
  alias __MODULE__
  defstruct [
    width: 5,
    height: 5,
    grid: %{}
  ]

  defimpl Poison.Encoder, for: Board do
    def encode(%Board{grid: grid} = board, options) do
      encodeable = grid
        |> Map.to_list()
        |> Map.new(fn({{x, y}, f}) -> {"#{x},#{y}", encode_feature(f)} end)
      Poison.Encoder.Map.encode(
        %{width: board.width,
          height: board.height,
          grid: encodeable},
        options
      )
    end

    defp encode_feature(%Unit{position: pos}), do: %{kind: :unit, player: pos}
    defp encode_feature(other), do: other
  end

  def new() do
    %Board{width: 5, height: 5, grid: %{{1, 2} => :water, {3, 2} => :water}}
  end

  def place(%Board{grid: grid} = board, %Unit{} = unit, x, y) do
    case grid[{x, y}] do
      :nil -> {
          :ok,
          %{board | grid: Map.put_new(grid, {x, y}, unit)}
      }
      _something -> {:err, :occupied}
    end
  end
  def place(%Board{grid: grid} = board, feature, x, y) do
    case grid[{x, y}] do
      :nil -> {:ok, %{board | grid: Map.put_new(grid, {x, y}, feature)}}
      _something -> {:err, :occupied}
    end
  end

  def units(board, position) do
    Enum.reduce(
      board.grid,
      [],
      fn
        ({{x, y}, %Unit{position: ^position} = unit}, units) ->
          [%{x: x, y: y, unit: unit} | units]
        (_, units) ->
          units
      end
    )
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

  ## Private

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

  defp unit_death(board, {x, y}) do
    grid = Map.delete(board.grid, {x, y})
    {
      %{board | grid: grid},
      [Event.new(:unit_died, %{x: x, y: y})]
    }
  end

  defp do_battle(_, %Unit{position: pos}, %Unit{position: pos}, _, _) do
    {:err, :noselfattack}
  end
  defp do_battle(board, unit, opponent, from, to) do
    cond do
      unit.attack > opponent.defense ->
        {board, e1} = unit_death(board, to)
        {board, e2} = do_move(board, unit, from, to)
        {state, events} = unless opponent.name == :monarch do
          {:ok, e1 ++ e2}
        else
          {:gameover, [Event.new(:gameover, %{winner: unit.position}) | e1] ++ e2}
        end
        {state, board, events}
      unit.attack == opponent.defense ->
        {board, e1} = unit_death(board, from)
        {board, e2} = unit_death(board, to)
        {state, events} = case {unit.name, opponent.name} do
          {:monarch, :monarch} -> {:gameover, [Event.new(:gameover, %{winner: :draw}) | e1] ++ e2}
          {:monarch, _} -> {:gameover, [Event.new(:gameover, %{winner: opponent.position}) | e1] ++ e2}
          {_, :monarch} -> {:gameover, [Event.new(:gameover, %{winner: unit.position}) | e1] ++ e2}
          _ -> {:ok, e1 ++ e2}
        end
        {state, board, events}
      unit.attack < opponent.defense ->
        {board, events} = unit_death(board, from)
        {state, events} = unless unit.name == :monarch do
          {:ok, events}
        else
          {:gameover, [Event.new(:gameover, %{winner: unit.position}) | events]}
        end
        {state, board, events}
    end
  end
end
