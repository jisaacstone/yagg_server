alias Yagg.Unit

defmodule Unit.Bomb do
  @behaviour Unit
  @impl Unit
  def new(position) do
    Unit.new(
      position: position,
      name: :bomb,
      attack: :immobile,
      defense: 0,
      triggers: %{
        death: Unit.Ability.Poison,
        move: Unit.Ability.Immobile,
      }
    )
  end
end
