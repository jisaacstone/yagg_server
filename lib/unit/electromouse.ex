alias Yagg.Unit
alias Yagg.Event
alias Yagg.Board.Grid
alias Yagg.Board.Action.Ability

defmodule Unit.Electromouse do
  @behaviour Unit

  @impl Unit
  def new(position) do
    Unit.new(
      position: position,
      name: :electromouse,
      attack: 3,
      defense: 4,
      ability: Unit.Electromouse.Mousetrap
    )
  end

  defmodule Mousetrap do
    @moduledoc """
    Set an invisible trap in the current square that captures units
    """
    use Ability, noreveal: :true

    @impl Ability
    def resolve(board, opts) do
      Grid.update(
        board,
        opts[:coords],
        &update/1
      )
    end

    def update(unit) do
      %{unit |
        name: :"electromouse trap",
        ability: :nil,
        triggers: %{
          move: Unit.Electromouse.Settrap,
          death: Unit.Electromousetrap.Trap
        }
      }
    end
  end

  defmodule Settrap do
    @moduledoc """
    Leave the unit capture trap behind
    """
    use Ability.AfterMove, noreveal: :true

    @impl Ability.AfterMove
    def after_move(board, %{unit: unit, from: from, to: to}) do
      position = unit.position
      {x, y} = from
      trap = Unit.Electromousetrap.new(position)
      grid = Map.put(board.grid, from, trap)
      events = [Event.NewUnit.new(position, x: x, y: y, unit: trap)]
      Grid.update(
        %{board | grid: grid},
        to,
        fn(u) -> %{
          u |
          triggers: %{},
          name: :electromouse,
          ability: Unit.Electromouse.Mousetrap
        } end,
        events
      )
    end
  end
end
