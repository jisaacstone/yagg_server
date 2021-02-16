alias Yagg.Unit
alias Yagg.Event
alias Yagg.Board.Grid
alias Yagg.Unit.Ability

defmodule Unit.JackoScare do
  @behaviour Unit

  @impl Unit
  def new(position) do
    Unit.new(
      position: position,
      name: :"jacko scare",
      attack: 7,
      defense: 4,
      ability: Unit.JackoScare.Scare
    )
  end

  defmodule Scare do
    @moduledoc """
    Surrounding units lose all abilities, triggers and -2 attack and defense.
    Can only be used once.
    """
    use Ability

    @impl Ability
    def resolve(board, opts) do
      {x, y} = opts[:coords]
      {board, global, private} = Enum.reduce(
        Grid.surrounding({x, y}),
        {board, [], []},
        fn({_, coord}, {board, global, priv}) ->
          scare_unit(coord, opts[:unit].position, board, global, priv)
        end
      )
      scare_event = Event.AbilityUsed.new(
        type: :scare,
        x: x,
        y: y
      )
      {board, events} = Grid.update(
        board,
        {x, y},
        fn(unit) -> %{unit | ability: :nil} end
      )
      all_events = [scare_event, Event.Multi.new(events: global) | private] ++ events
      {board, all_events}
    end

    defp scare_unit(coord, position, board, global, private) do
      scared(
        Grid.update(
          board,
          coord,
          fn
            (%{position: ^position}) -> :no_update
            (%{monarch: :true} = monarch) -> %{monarch |
              attack: max(monarch.attack - 2, 1),
              defense: max(monarch.defense - 2, 0),
            }
            (enemy) -> %{enemy |
              attack: max(enemy.attack - 2, 1),
              defense: max(enemy.defense - 2, 0),
              ability: :nil,
              triggers: %{}
            }
          end
        ),
      global,
      private)
    end

    defp scared({board, []}, global, private) do
      {board, global, private}
    end
    defp scared({board, [e]}, global, private) do
      {board, global, [e | private]}
    end
    defp scared({board, [g, p]}, global, private) do
      {board, [g | global], [p | private]}
    end
  end
end
