alias Yagg.Unit
alias Yagg.Board
alias Yagg.Board.Grid
alias Yagg.Board.Action.Ability

defmodule Unit.Tinker do
  @behaviour Unit
  @impl Unit
  alias __MODULE__
  def new(position) do
    Unit.new(
      position,
      :tinker,
      3,
      2,
      Unit.Tinker.Tink
    )
  end

  def tinktonk(board, opts, directions, next_ability) do
    {board, events} = Enum.reduce(
      directions,
      {board, []},
      fn(direction, {board, events}) ->
        Grid.update(
          board,
          Grid.next(direction, opts[:coords]),
          fn(unit) -> %{unit | attack: unit.attack + 2} end,
          events)
      end
    )
    Grid.update(
      board,
      opts[:coords],
      fn(unit) -> %{unit | ability: next_ability} end,
      events)
  end

  defmodule Tonk do
    @moduledoc """
    Give units to the right and left +2 attack
    """
    use Ability
    @impl Ability
    def resolve(%Board{} = board, opts) do
      Tinker.tinktonk(board, opts, [:east, :west], Tinker.Tink)
    end
  end

  defmodule Tink do
    @moduledoc """
    Give units to the front and back +2 attack
    """
    use Ability
    @impl Ability
    def resolve(%Board{} = board, opts) do
      Tinker.tinktonk(board, opts, [:north, :south], Tinker.Tonk)
    end
  end
end

