alias Yagg.Unit
alias Yagg.Board
alias Yagg.Board.Grid
alias Yagg.Board.Action.Ability

defmodule Unit.Explody do
  @behaviour Unit
  @impl Unit
  def new(position) do
    Unit.new(
      position,
      :explody,
      3,
      2,
      :nil,
      %{death: Unit.Explody.Selfdestruct}
    )
  end

  defmodule Selfdestruct do
    @moduledoc "Destroy everything within 1 square radius"
    use Ability

    def resolve(board, opts) do
      Enum.reduce(
        [opts[:coords] | Grid.surrounding(opts[:coords])],
        {board, []},
        fn({_, coord}, b_e) ->
          killunit({coord, board.grid[coord]}, b_e)
        end
      )
    end

    defp killunit({coords, %Unit{} = unit}, {board, events}) do
      {board, newevents} = Board.unit_death(board, unit, coords)
      {board, newevents ++ events}
    end
    defp killunit(_, state) do
      state
    end
  end
end
