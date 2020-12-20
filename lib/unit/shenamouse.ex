alias Yagg.Unit
alias Yagg.Event
alias Yagg.Board.Grid
alias Yagg.Table.Player
alias Yagg.Board.Action.Ability

defmodule Unit.Shenamouse do
  @behaviour Unit
  @impl Unit
  def new(position) do
    Unit.new(
      position: position,
      name: :shenamouse,
      attack: 1,
      defense: 6,
      ability: Unit.Shenamouse.Spy,
      triggers: %{
        death: Unit.Shenamouse.SpyAttacker
      }
    )
  end

  def reveal({x, y}, board, position, events \\ []) do
    enemy = Player.opposite(position)
    {board, events} = case board.grid[{x, y}] do
      %Unit{visible: :all} -> {board, events}
      %Unit{position: ^enemy} ->
        Grid.update(
          board,
          {x, y},
          fn(u) -> %{u | visible: :all} end,
          [Event.AbilityUsed.new(position, type: :scan, x: x, y: y) | events]
        )
      _ -> {board, events}
    end
    {board, events, position}
  end
end

defmodule Unit.Shenamouse.SpyAttacker do
  @moduledoc """
  Reveal attacker
  """
  use Ability, noreveal: :true

  @impl Ability
  def resolve(board, opts) do
    case opts[:opponent] do
      :nil -> {board, []}
      {_, coord} ->
        position = opts[:unit].position
        {board, events, _} = Unit.Shenamouse.reveal(coord, board, position)
        {board, events}
    end
  end
end

defmodule Unit.Shenamouse.Spy do
  @moduledoc """
  Reveal adjacent units
  """
  use Ability, noreveal: :true

  @impl Ability
  def resolve(board, opts) do
    coord = opts[:coords]
    position = opts[:unit].position
    {board, events, _} = Enum.reduce(
      Grid.surrounding(coord),
      {board, [], position},
      fn({_, coord}, {b, e, p}) -> Unit.Shenamouse.reveal(coord, b, p, e) end
    )
    {board, events}
  end
end
