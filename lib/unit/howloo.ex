alias Yagg.Unit
alias Yagg.Board.Grid
alias Yagg.Board.Action.Ability

defmodule Unit.Howloo do
  alias __MODULE__
  @behaviour Unit
  @impl Unit
  def new(position) do
    Unit.new(
      position,
      :howloo,
      3,
      4,
      Howloo.Horseshoe
    )
  end

  defmodule Horseshoe do
    @moduledoc """
    Throw a horseshoe to the front, if it hits a unit that unit's attack is reduced by 2 (minimum 1)
    """
    use Ability
    @impl Ability
    def resolve(board, opts) do
      direction = Grid.cardinal(opts[:unit].position, :front)
      case Grid.projectile(board, opts[:coords], direction) do
        {coord, _} ->
          Grid.update(board, coord, fn(unit) -> %{unit | attack: max(1, unit.attack - 2)} end)
        _other ->
          {board, []}
      end
    end
  end
end
