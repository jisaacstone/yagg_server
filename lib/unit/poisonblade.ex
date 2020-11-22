alias Yagg.Unit
alias Yagg.Board
alias Yagg.Board.Action.Ability

defmodule Unit.Poisonblade do
  @behaviour Unit

  @impl Unit
  def new(position) do
    Unit.new(
      name: :poisonblade,
      attack: 3,
      defense: 4,
      triggers: %{
        death: Unit.Poisonblade.Poison
      },
      position: position
    )
  end

  defmodule Poison do
    @moduledoc "Poisons any units that touch it"
    use Ability, noreveal: :true

    def resolve(board, opts) do
      case opts[:opponent] do
        :nil -> {board, []}
        {%Unit{}, coords} -> Board.unit_death(board, coords)
      end
    end
  end
end
