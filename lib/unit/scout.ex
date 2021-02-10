alias Yagg.Unit
alias Yagg.Board
alias Yagg.Unit.Trigger.BeforeAttack

defmodule Unit.Scout do
  @behaviour Unit
  @impl Unit
  def new(position) do
    Unit.new(
      position: position,
      name: :scout,
      attack: 1,
      defense: 6,
      triggers: %{
        attack: Unit.Scout.Spy,
        move: Unit.Ability.Slide
      }
    )
  end

  defmodule Spy do
    @moduledoc """
    Reveals any unit it attacks
    """
    use BeforeAttack
    @impl BeforeAttack
    def before_attack(board, data) do
      {board, e1} = Unit.Ability.reveal(data.to, board, data.unit.position)
      {board, e2} = Board.do_battle(board, data.unit, data.opponent, data.from, data.to)
      {board, e1 ++ e2}
    end
  end
end
