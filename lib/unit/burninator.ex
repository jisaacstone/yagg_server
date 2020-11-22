alias Yagg.Unit
alias Yagg.Board
alias Yagg.Board.Action.Ability

defmodule Unit.Burninator do
  @behaviour Unit

  @impl Unit
  def new(position) do
    Unit.new(
      name: :burninator,
      attack: 3,
      defense: 2,
      ability: Unit.Burninator.Rowburn,
      position: position
    )
  end

  defmodule Rowburn do
    @moduledoc "Destory all units in the same row"
    use Ability

    def resolve(board, opts) do
      {_, y} = opts[:coords]
      Enum.reduce(
        board.grid,
        {board, []},
        &burn_unit(&1, &2, y)
      )
    end

    defp burn_unit({{x, y}, %Unit{}}, {board, events}, y) do
      {board, newevents} = Board.unit_death(board, {x, y})
      {board, newevents ++ events}
    end
    defp burn_unit(_, acc, _) do
      acc
    end
  end
end
