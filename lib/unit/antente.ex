alias Yagg.Unit
alias Yagg.Event
alias Yagg.Board
alias Yagg.Board.Grid
alias Yagg.Board.Action.Ability

defmodule Unit.Antente do
  @behaviour Unit

  @impl Unit
  def new(position) do
    Unit.new(
      name: :antente,
      attack: 5,
      defense: 3,
      triggers: %{
        attack: Unit.Antente.Visible,
      },
      visible: :none,
      position: position
    )
  end
end

defmodule Unit.Antente.Invisible do
  @moduledoc """
  Become invisible until your next attack
  """
  use Ability, noreveal: :true

  @impl Ability
  def resolve(board, opts) do
    {x, y} = opts[:coords]
    {board, events} = Grid.update(
      board,
      {x, y},
      &make_invisible/1
    )
    {board, [Event.ThingGone.new(x: x, y: y) | events]}
  end

  defp make_invisible(unit) do
    %{unit | visible: :none, ability: :nil, triggers: %{ attack: Unit.Antente.Visible }}
  end

end

defmodule Unit.Antente.Visible do
  @moduledoc """
  Becomes visible to opponent
  """
  use Ability

  @impl Ability
  def resolve(board, opts) do
    %{position: position} = opts[:unit]
    {x, y} = opts[:from]
    vis_event = Event.UnitPlaced.new(x: x, y: y, player: position)
    {board, e1} = Grid.update(board, opts[:from], &make_visible/1, [vis_event])
    {board, e2} = Board.do_battle(board, opts[:unit], opts[:opponent], opts[:from], opts[:to])
    {board, e1 ++ e2}
  end

  defp make_visible(unit) do
    unit = Unit.make_visible(unit, :player)
    %{unit | ability: Unit.Antente.Invisible, triggers: %{}}
  end
end
