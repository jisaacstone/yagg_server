alias Yagg.Unit
alias Yagg.Board.Grid
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
        {board, events} = Unit.Ability.reveal(coord, board, position)
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
      {board, []},
      fn({_, coord}, {b, e}) -> Unit.Ability.reveal(coord, b, position, e) end
    )
    {board, events}
  end
end
