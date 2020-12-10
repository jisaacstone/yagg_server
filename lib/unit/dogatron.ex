alias Yagg.Unit
alias Yagg.Board
alias Yagg.Board.Action.Ability

defmodule Unit.Dogatron do
  @behaviour Unit

  @impl Unit
  def new(position) do
    Unit.new(
      name: :dogatron,
      attack: 1,
      defense: 0,
      triggers: %{
        death: Unit.Dogatron.Upgrade
      },
      position: position
    )
  end

  defmodule Upgrade do
    @moduledoc """
    Add a copy to hand with +2 attack and defense.
    """
    use Ability.OnDeath, noreveal: true
    @impl Ability.OnDeath
    def on_death(%Board{} = board, data) do
      %{name: name, attack: attack, defense: defense, position: position} = data.unit
      {board, e1} = case board.grid[data.coord] do
        :nil -> {board, []}
        %Unit{name: ^name} -> Board.unit_death(board, data.coord)
      end
      newunit = %{data.unit | attack: attack + 2, defense: defense + 2}
      {board, e2} = Board.Hand.add_unit(board, position, newunit)
      {board, e1 ++ e2}
    end
  end
end
