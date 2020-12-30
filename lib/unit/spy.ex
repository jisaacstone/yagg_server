alias Yagg.Unit

defmodule Unit.Spy do
  @behaviour Unit
  @impl Unit
  def new(position) do
    Unit.new(
      position: position,
      name: :spy,
      attack: 9,
      defense: 0
    )
  end
end
