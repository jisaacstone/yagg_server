alias Yagg.Unit
alias Yagg.Event
alias Yagg.Board
alias Yagg.Unit.Ability

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
    @moduledoc "Destroy all units in the same row"
    use Ability

    def resolve(board, opts) do
      {_, y} = opts[:coords]
      {width, _} = board.dimensions
      {board, effects, events} = Enum.reduce(
        0..width - 1,
        {board, [], []},
        fn(x, acc) -> burn_unit(x, y, Board.Grid.thing_at(board, {x, y}), acc) end
      )
      {board, [Event.Multi.new(events: effects) | events]}
    end

    defp burn_unit(x, y, %Unit{}, {board, effects, events}) do
      {board, newevents} = Board.unit_death(board, {x, y})
      {board, [ability_event(x, y) | effects], newevents ++ events}
    end
    defp burn_unit(x, y, _, {board, effects, events}) do
      {board, [ability_event(x, y) | effects], events}
    end

    defp ability_event(x, y) do
      Event.AbilityUsed.new(
        type: :fire,
        x: x,
        y: y
      )
    end
  end
end
