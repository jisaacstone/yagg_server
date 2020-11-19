alias Yagg.Unit
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

  def reveal(coord, board, position, events \\ []) do
    enemy = Player.opposite(position)
    {board, events} = case board.grid[coord] do
      %Unit{visible: :all} -> {board, events}
      %Unit{position: ^enemy} ->
        Grid.update(board, coord, fn(u) -> %{u | visible: :all} end, events)
      _ -> {board, events}
    end
    {board, events, position}
  end
end

defmodule Unit.Shenamouse.SpyAttacker do
  @moduledoc """
  reveal all information about any attacker
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
  reveal all information about surrounding units
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
