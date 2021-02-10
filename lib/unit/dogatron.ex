alias Yagg.Unit
alias Yagg.Board

defmodule Unit.Dogatron do
  @behaviour Unit

  @impl Unit
  def new(position) do
    Unit.new(
      name: :dogatron,
      attack: 1,
      defense: 0,
      triggers: %{
        death: Unit.Dogatron.Armor
      },
      position: position
    )
  end

  defmodule Armor do
    @moduledoc """
    Add a copy to hand with +2 defense.
    """
    use Unit.Trigger.OnDeath, noreveal: true
    @impl Unit.Trigger.OnDeath
    def on_death(%Board{} = board, data) do
      %{name: name, defense: defense, position: position} = data.unit
      {board, e1} = case board.grid[data.coord] do
        :nil -> {board, []}
        %Unit{name: ^name} -> Board.unit_death(board, data.coord)
      end
      newunit = %{data.unit | ability: Unit.Dogatron.Upgrade, defense: defense + 2}
      {board, e2} = Board.Hand.add_unit(board, position, newunit)
      {board, e1 ++ e2}
    end
  end

  defmodule Upgrade do
    @moduledoc """
    Add a copy to hand with +2 attack.
    """
    use Unit.Trigger.OnDeath, noreveal: true
    @impl Unit.Trigger.OnDeath
    def on_death(%Board{} = board, data) do
      %{name: name, attack: attack, position: position} = data.unit
      {board, e1} = case board.grid[data.coord] do
        :nil -> {board, []}
        %Unit{name: ^name} -> Board.unit_death(board, data.coord)
      end
      newunit = %{data.unit | attack: attack + 2, ability: Unit.Dogatron.Armor}
      {board, e2} = Board.Hand.add_unit(board, position, newunit)
      {board, e1 ++ e2}
    end
  end
end
