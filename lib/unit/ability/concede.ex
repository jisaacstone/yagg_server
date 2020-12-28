alias Yagg.Board.Action
alias Yagg.Event
alias Yagg.Unit
alias Yagg.Table.Player
alias Yagg.Board.State

defmodule Unit.Ability.Concede do
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

