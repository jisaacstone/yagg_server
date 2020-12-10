alias Yagg.Unit
alias Yagg.Board
alias Yagg.Event
alias Yagg.Board.Action.Ability
defmodule Unit.Mediacreep do
  @behaviour Unit
  @impl Unit
  def new(position) do
    Unit.new(
      position,
      :mediacreep,
      5,
      4,
      :nil,
      %{
        move: Unit.Mediacreep.Duplicate
      }
    )
  end

  defmodule Duplicate do
    @moduledoc """
    Leave behind a replica with -2 attack and defense
    """
    use Ability.AfterMove

    @impl Ability.AfterMove
    def after_move(%Board{} = board, %{from: from, unit: unit}) do
      {x, y} = from
      copy = %{
        unit |
        attack: unit.attack - 2,
        defense: unit.defense - 2
      }
      copy = if copy.attack < 2 or copy.defense < 2 do
        %{copy | triggers: %{}}
      else 
        copy
      end
      grid = Map.put(board.grid, from, copy)
      {
        %{board | grid: grid},
        [
          Event.UnitPlaced.new(player: unit.position, x: x, y: y),
          Event.NewUnit.new(unit.position, x: x, y: y, unit: copy)
        ]
      }
    end
  end
end
