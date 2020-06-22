alias Yagg.Unit
alias Yagg.Board.Action.Ability

defmodule Unit.Pushie do
  @behaviour Unit
  @impl Unit
  def new(position) do
    Unit.new(
      position,
      :pushie,
      3,
      0,
      Ability.Push
    )
  end
end
