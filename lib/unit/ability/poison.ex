alias Yagg.Unit
alias Yagg.Board
alias Yagg.Board.Action.Ability

defmodule Unit.Ability.Poison do
  @moduledoc "Poisons any units that touch it"
  use Ability, noreveal: :true

  def resolve(board, opts) do
    case opts[:opponent] do
      :nil -> {board, []}
      {%Unit{}, coords} -> Board.unit_death(board, coords)
    end
  end
end
