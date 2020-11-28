alias Yagg.Unit
alias Yagg.Event
alias Yagg.Board
alias Yagg.Board.Grid
alias Yagg.Board.Action.Ability

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
      Maycorn.Spark.Front,
      %{
        death: Maycorn.Spark.All
      }
    )
  end

  def spark(board, attack, coord, direction, next_ability) do
    {board, e1} = Grid.update(
      board,
      coord,
      fn(unit) -> %{unit | ability: next_ability} end
    )
    {board, e2} = sparkle(board, attack, direction, coord)
    {board, e2 ++ e1}
  end

  defp sparkle(board, attack, direction, from) do
    case Grid.projectile(board, Grid.next(direction, from), direction) do
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
  defmodule Left do
    @moduledoc """
    Fire a spark to the left
    the spark will kill any unit with defense less than maycorn's attack
    sparks are blocked by blocks but not by water
    """
    use Ability
    @impl Ability
    def resolve(board, opts) do
      Maycorn.spark(board, opts[:unit].attack, opts[:coords], Grid.cardinal(opts[:unit].position, :left), Maycorn.Spark.Front)
    end
  end
  defmodule Front do
    @moduledoc """
    Fire a spark to the front
    the spark will kill any unit with defense less than maycorn's attack
    sparks are blocked by blocks but not by water
    """
    use Ability
    @impl Ability
    def resolve(board, opts) do
      Maycorn.spark(board, opts[:unit].attack, opts[:coords], Grid.cardinal(opts[:unit].position, :front), Maycorn.Spark.Right)
    end
  end
  defmodule Right do
    @moduledoc """
    Fire a spark to the right
    the spark will kill any unit with defense less than maycorn's attack
    sparks are blocked by blocks but not by water
    """
    use Ability
    @impl Ability
    def resolve(board, opts) do
      Maycorn.spark(board, opts[:unit].attack, opts[:coords], Grid.cardinal(opts[:unit].position, :right), Maycorn.Spark.Back)
    end
  end
  defmodule Back do
    @moduledoc """
    Fire a spark to the back
    the spark will kill any unit with defense less than maycorn's attack
    sparks are blocked by blocks but not by water
    """
    use Ability
    @impl Ability
    def resolve(board, opts) do
      Maycorn.spark(board, opts[:unit].attack, opts[:coords], Grid.cardinal(opts[:unit].position, :back), Maycorn.Spark.Left)
    end
  end
  defmodule All do
    @moduledoc """
    Fire a weak spark in all directions
    the spark will kill any unit with defense of 0
    sparks are blocked by blocks but not by water
    """
    use Ability
    @impl Ability
    def resolve(board, opts) do
      {board, [a1 | e1]} = Maycorn.spark(board, 1, opts[:coords], :north, nil)
      {board, [a2 | e2]} = Maycorn.spark(board, 1, opts[:coords], :south, nil)
      {board, [a3 | e3]} = Maycorn.spark(board, 1, opts[:coords], :east, nil)
      {board, [a4 | e4]} = Maycorn.spark(board, 1, opts[:coords], :west, nil)
      {board, [Event.Multi.new(events: [a1, a2, a3, a4]) | e1 ++ e2 ++ e3 ++ e4]}
    end
  end
end
