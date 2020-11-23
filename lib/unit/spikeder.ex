alias Yagg.Unit

defmodule Unit.Spikeder do
  @behaviour Unit
  @impl Unit
  def new(position) do
    Unit.new(
      position,
      :spikeder,
      3,
      2,
      :nil,
      %{
        death: Unit.Ability.Poison,
        move: Unit.Ability.Slide,
      }
    )
  end
end
