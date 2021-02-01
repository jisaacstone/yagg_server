alias Yagg.Unit
alias Yagg.Event
alias Yagg.Board.Action.Ability

defmodule Unit.Flag do
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
        death: Unit.Flag.Captured,
        move: Ability.Immobile,
      }
    )
  end

  defp name(:north), do: :"northern colors"
  defp name(:south), do: :"southern banner"

  defmodule Captured do
    @moduledoc """
    Lose the game
    """
    use Ability

    @impl Ability
    def resolve(board, opts) do
      {board, events} = Unit.Ability.Concede.resolve(board, opts)
      case opts[:opponent] do
        :nil -> {board, events}
        {_, coord} ->
          event = Event.AbilityUsed.new(type: :capture, coord: coord, name: opts[:unit].name)
          {board, events ++ [event]}
      end
    end
  end
end
