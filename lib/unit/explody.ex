alias Yagg.Unit
alias Yagg.Event
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
      5,
      2,
      :nil,
      %{death: Unit.Explody.Selfdestruct}
    )
  end

  defmodule Selfdestruct do
    @moduledoc "Destroy units in this and adjacent squares"
    use Ability.OnDeath

    @impl Ability.OnDeath
    def on_death(board, data) do
      {board, effects, events} = Enum.reduce(
        [{:_, data.coord} | Grid.surrounding(data.coord)],
        {board, [], []},
        fn({_, {x, y}}, b_e) ->
          killunit({x, y}, Grid.thing_at(board, {x, y}), b_e)
        end
      )
      {board, [Event.Multi.new(events: effects) | events]}
    end

    defp killunit(coord, %Unit{}, {board, effects, events}) do
      {board, newevents} = Board.unit_death(board, coord)
      {board, [ability_event(coord) | effects], newevents ++ events}
    end
    defp killunit(_, :out_of_bounds, state) do
      state
    end
    defp killunit(coord, _, {board, effects, events}) do
      {board, [ability_event(coord) | effects], events}
    end

    defp ability_event({x, y}) do
      Event.AbilityUsed.new(
        type: :fire,
        x: x,
        y: y
      )
    end
  end
end
