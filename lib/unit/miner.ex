alias Yagg.Unit
alias Yagg.Board
alias Yagg.Board.Action.Ability.BeforeAttack

defmodule Unit.Miner do
  @behaviour Unit
  @impl Unit
  def new(position) do
    Unit.new(
      position: position,
      name: :miner,
      attack: 1,
      defense: 6,
      triggers: %{
        attack: Unit.Miner.Defuse
      }
    )
  end

  defmodule Defuse do
    @moduledoc """
    will not trigger the death trigger of any unit it kills
    """
    use BeforeAttack

    @impl BeforeAttack
    def before_attack(board, data) do
      board = defuse(board, data.to)
      {board, events} = Board.do_battle(board, data.unit, data.opponent, data.from, data.to)
      board = refuse(board, data.to, data.opponent)
      {board, events}
    end

    defp defuse(board, coord) do
      grid = case Board.Grid.thing_at(board, coord) do
        %{triggers: %{death: _}} = unit ->
          {_, triggers} = Map.pop!(unit.triggers, :death)
          Map.put(board.grid, coord, %{unit | triggers: triggers})
        _ -> board.grid
      end
      %{board | grid: grid}
    end

    defp refuse(board, coord, %{triggers: %{death: death}}) do
      unit = board.grid[coord]
      triggers = %{unit.triggers | death: death}
      %{board | grid: Map.put(board.grid, coord, %{unit | triggers: triggers})}
    end

  end
end
