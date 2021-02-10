alias Yagg.Unit
alias Yagg.Event
alias Yagg.Table.Player
alias Yagg.Board.Grid
alias Yagg.Unit.Ability
alias Yagg.Unit.Trigger.OnDeath

defmodule Unit.Electromousetrap do
  @behaviour Unit

  @impl Unit
  def new(position) do
    Unit.new(
      position: position,
      name: :electromousetrap,
      attack: :immobile,
      defense: 0,
      triggers: %{
        move: Ability.Immobile,
        death: Unit.Electromousetrap.Trap
      },
      visible: :none
    )
  end

  defmodule Trap do
    @moduledoc """
    Invisible. Captures attacker, giving you control
    """
    use OnDeath, noreveal: :true

    @impl OnDeath
    def on_death(board, %{unit: unit, opponent: opponent}) do
      control(board, opponent, unit)
    end

    defp control(board, :nil, _) do
      {board, []}
    end
    defp control(board, {unit, {x, y}}, %{position: position}) do
      {board, events} = Grid.update(
        board,
        {x, y},
        fn(u) -> %{u | position: position, visible: :all} end
      ) |> maybe_gameover(unit, unit.triggers[:death])
      event = Event.UnitChanged.new(Player.opposite(position), x: x, y: y, unit: board.grid[{x, y}])
      {board, [event | events]}
    end

    defp maybe_gameover({board, events}, unit, Ability.Concede) do
      {board, e2} = Ability.Concede.resolve(board, unit: unit)
      {board, events ++ e2}
    end
    defp maybe_gameover(b_e, _, _), do: b_e
  end
end
