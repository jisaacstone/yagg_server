alias Yagg.Unit
alias Yagg.Board.Action.Ability

defmodule Yagg.Unit.Flag do
  @behaviour Unit
  @impl Unit
  def new(position) do
    Unit.new(
      position: position,
      name: name(position),
      monarch: :true,
      attack: :immobile,
      defense: 0,
      triggers: %{
        death: Unit.Ability.Concede,
        move: Ability.Immobile,
      }
    )
  end

  defp name(:north), do: :"northern colors"
  defp name(:south), do: :"southern banner"
end
