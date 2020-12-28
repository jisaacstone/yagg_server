alias Yagg.Unit

defmodule Unit.Monarch do
  @behaviour Unit
  @impl Unit
  def new(position) do
    Unit.new(
      position: position,
      name: :monarch,
      monarch: :true,
      attack: 1,
      defense: 0,
      triggers: %{death: Unit.Ability.Concede}
    )
  end
end
