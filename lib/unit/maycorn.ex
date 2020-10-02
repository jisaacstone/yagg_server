alias Yagg.Unit
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
    {board, events} = sparkle(board, attack, direction, Grid.next(direction, coord))
    Grid.update(
      board,
      coord,
      fn(unit) -> %{unit | ability: next_ability} end,
      events)
  end

  defp sparkle(board, attack, direction, coord) do
    case Grid.projectile(board, coord, direction) do
      {coord, %Unit{defense: a}} when a < attack ->
        Board.unit_death(board, coord)
      _other -> {board, []}
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
      {board, e1} = Maycorn.spark(board, 1, opts[:coords], :north, nil)
      {board, e2} = Maycorn.spark(board, 1, opts[:coords], :south, nil)
      {board, e3} = Maycorn.spark(board, 1, opts[:coords], :east, nil)
      {board, e4} = Maycorn.spark(board, 1, opts[:coords], :west, nil)
      {board, e1 ++ e2 ++ e3 ++ e4}
    end
  end
end
