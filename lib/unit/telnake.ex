alias Yagg.Unit
alias Yagg.Board
alias Yagg.Board.Grid

defmodule Unit.Telnake do
  @behaviour Unit

  @impl Unit
  def new(position) do
    Unit.new(
      name: :telnake,
      attack: 5,
      defense: 6,
      ability: Unit.Telnake.Strike,
      position: position
    )
  end

  defmodule Strike do
    @moduledoc """
    Move forward twice.
    """
    use Unit.Ability

    @impl Unit.Ability
    def resolve(board, opts) do
      from = opts[:coords]
      position = opts[:unit].position
      direction = Grid.cardinal(position, :front)
      mid = Grid.next(direction, from)
      case Board.move(board, position, from, mid) do
        {:err, _} -> {board, []}
        {board, e1} ->
          to = Grid.next(direction, mid)
          case Board.move(board, position, mid, to) do
            {:err, _} -> {board, e1}
            {board, e2} -> {board, e1 ++ e2}
          end
      end
    end
  end
end
