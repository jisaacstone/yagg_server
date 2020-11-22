alias Yagg.Unit
alias Yagg.Board.Grid
alias Yagg.Board.Action.Ability

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
    use Ability, noreveal: :true

    @impl Ability
    def resolve(board, opts) do
      control(board, opts[:opponent], opts[:unit])
    end

    defp control(board, :nil, _) do
      {board, []}
    end
    defp control(board, {unit, coord}, %{position: position}) do
      Grid.update(
        board,
        coord,
        fn(u) -> %{u | position: position} end
      ) |> maybe_gameover(unit, unit.triggers[:death])
    end

    defp maybe_gameover({board, events}, unit, Ability.Concede) do
      {board, e2} = Ability.Concede.resolve(board, unit: unit)
      {board, events ++ e2}
    end
    defp maybe_gameover(b_e, _, _), do: b_e
  end
end
