alias Yagg.Unit
alias Yagg.Event
alias Yagg.Board
alias Yagg.Board.Grid
alias Yagg.Unit.Ability

defmodule Unit.Maycorn do
  alias __MODULE__
  @behaviour Unit
  @impl Unit
  def new(position) do
    Unit.new(
      position,
      :maycorn,
      3,
      4,
      Maycorn.Spark.Spark,
      %{
        death: Maycorn.Spark.All
      }
    )
  end

  def spark(board, attack, from, direction) do
    case Grid.projectile(board, from, direction) do
      {coord, %Unit{defense: a}} when a < attack ->
        ability_event = Event.AbilityUsed.new(
          type: :projectile,
          subtype: :spark,
          from: from,
          to: coord
        )
        {board, events} = Board.unit_death(board, coord)
        {board, [ability_event | events]}
      {coord, _} ->
        ability_event = Event.AbilityUsed.new(
          type: :projectile,
          subtype: :spark,
          from: from,
          to: coord
        )
        {board, [ability_event]}
    end
  end
end

defmodule Unit.Maycorn.Spark do
  alias Unit.Maycorn
  defmodule Spark do
    @moduledoc """
    Fire a spark forward that kills units having defense less than this unit's attack
    """
    use Ability
    @impl Ability
    def resolve(board, opts) do
      Maycorn.spark(board, opts[:unit].attack, opts[:coords], Grid.cardinal(opts[:unit].position, :front))
    end
  end
  defmodule All do
    @moduledoc """
    Fire a spark in all directions that kills units having 0 defense
    """
    use Unit.Trigger.OnDeath
    @impl Unit.Trigger.OnDeath
    def on_death(board, %{coord: coord}) do
      {board, [a1 | e1]} = Maycorn.spark(board, 1, coord, :north)
      {board, [a2 | e2]} = Maycorn.spark(board, 1, coord, :south)
      {board, [a3 | e3]} = Maycorn.spark(board, 1, coord, :east)
      {board, [a4 | e4]} = Maycorn.spark(board, 1, coord, :west)
      {board, [Event.Multi.new(events: [a1, a2, a3, a4]) | e1 ++ e2 ++ e3 ++ e4]}
    end
  end
end
