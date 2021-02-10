alias Yagg.Unit
alias Yagg.Event
alias Yagg.Board.Grid
alias Yagg.Unit.Ability

defmodule Unit.Howloo do
  alias __MODULE__
  @behaviour Unit
  @impl Unit
  def new(position) do
    Unit.new(
      position,
      :howloo,
      5,
      4,
      Howloo.Horseshoe
    )
  end

  defmodule Horseshoe do
    @moduledoc """
    Throw a horseshoe forward which reduces a units attack by 2 (minimum 1)
    """
    use Ability
    @impl Ability
    def resolve(board, opts) do
      direction = Grid.cardinal(opts[:unit].position, :front)
      case Grid.projectile(board, opts[:coords], direction) do
        {coord, %Unit{attack: a}} when is_integer(a) and a > 2 ->
          ability_event = Event.AbilityUsed.new(
            type: :projectile,
            subtype: :horseshoe,
            from: opts[:coords],
            to: coord
          )
          Grid.update(
            board,
            coord,
            fn(unit) -> %{unit | attack: unit.attack - 2} end,
            [ability_event]
          )
        {coord, _} ->
          ability_event = Event.AbilityUsed.new(
            type: :projectile,
            subtype: :horseshoe,
            from: opts[:coords],
            to: coord
          )
          {board, [ability_event]}
      end
    end
  end
end
