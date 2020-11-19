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
    Set a trap that will capture any unit that moves to the square
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
    use Ability, noreveal: :true

    @impl Ability
    def resolve(board, opts) do
      position = opts[:unit].position
      {x, y} = opts[:from]
      trap = Unit.Electromousetrap.new(position)
      grid = Map.put(board.grid, opts[:from], trap)
      events = [Event.NewUnit.new(position, x: x, y: y, unit: trap)]
      Grid.update(
        %{board | grid: grid},
        opts[:to],
        fn(u) -> %{u | triggers: %{}, name: :electromouse} end,
        events
      )
    end
  end
end
