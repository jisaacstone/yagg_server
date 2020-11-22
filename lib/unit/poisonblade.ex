alias Yagg.Unit

defmodule Unit.Poisonblade do
  @behaviour Unit

  @impl Unit
  def new(position) do
    Unit.new(
      name: :poisonblade,
      attack: 3,
      defense: 4,
      triggers: %{
        death: Unit.Ability.Poison
      },
      position: position
    )
  end
end
