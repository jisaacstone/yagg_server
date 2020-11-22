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
    Return to your hand and gain +2 attack and +2 defense
    """
    use Ability, noreveal: true
    @impl Ability
    def resolve(%Board{} = board, opts) do
      %{name: name, attack: attack, defense: defense, position: position} = opts[:unit]
      {board, e1} = case board.grid[opts[:coords]] do
        :nil -> {board, []}
        %Unit{name: ^name} -> Board.unit_death(board, opts[:coords])
      end
      newunit = %{opts[:unit] | attack: attack + 2, defense: defense + 2}
      {board, e2} = Board.Hand.add_unit(board, position, newunit)
      {board, e1 ++ e2}
    end
  end
end
