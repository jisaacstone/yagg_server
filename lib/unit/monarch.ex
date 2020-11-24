alias Yagg.Unit
alias Yagg.Board.Action.Ability

defmodule Unit.Monarch do
  @behaviour Unit
  @impl Unit
  def new(position) do
    Unit.new(
      position,
      :monarch,
      1,
      0,
      :nil,
      %{death: Ability.Concede}
    )
  end
end
