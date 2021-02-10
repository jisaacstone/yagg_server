alias Yagg.Unit
alias Yagg.Event
alias Yagg.Board.Grid
alias Yagg.Board.Hand
alias Yagg.Unit.Ability

defmodule Unit.Sparky do
  @behaviour Unit

  @impl Unit
  def new(position) do
    Unit.new(
      name: :sparky,
      attack: 1,
      defense: 2,
      ability: Unit.Sparky.Copyleft,
      position: position
    )
  end

  defmodule Copyleft do
    @moduledoc """
    Duplicate the left unit into your hand
    """
    use Ability

    @impl Ability
    def resolve(board, opts) do
      pos = opts[:unit].position
      {x, y} = Grid.cardinal(pos, :left) |> Grid.next(opts[:coords])
      case board.grid[{x, y}] do
        %Unit{} = unit ->
          copy = %{unit | position: pos}
          {board, events} = Hand.add_unit(board, pos, copy)
          {board, [Event.AbilityUsed.new(pos, type: :scan, x: x, y: y) | events]}
        _ -> {board, []}
      end
    end
  end
end
