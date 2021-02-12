alias Yagg.Unit
alias Yagg.Event
alias Yagg.Board
alias Yagg.Board.Action
alias Yagg.Board.Grid

defmodule Action.Ability do
  @behaviour Action

  @enforce_keys [:x, :y]
  defstruct @enforce_keys

  @impl Action
  def resolve(data, %Board{state: :battle} = board, position) do
    coord = {data.x, data.y}
    case ability_at(board, coord, position) do
      {:err, _} = err -> err
      {:ok, unit} ->
        board = if unit.ability.reveal?() and not Unit.visible?(unit, :ability) do
          {board, _} = Grid.update(board, coord, fn(u) -> Unit.make_visible(u, [:ability, :name]) end)
          board
        else
          board
        end
        {board, events} = unit.ability.resolve(board, unit: unit, coords: coord)
        event = Event.ShowAbility.new(
          x: data.x,
          y: data.y,
          type: :ability,
          reveal: %{
            name: Unit.encode_field(unit, :name),
            ability: Unit.encode_field(unit, :ability)
          }
        )
        {board, [event | events]}
    end
  end

  defp ability_at(board, coords, position) do
    case board.grid[coords] do
      %Unit{ability: :nil} -> {:err, :noable}
      %Unit{position: ^position} = unit -> {:ok, unit}
      %Unit{} -> {:err, :unowned}
      _ -> {:err, :nounit}
    end
  end
end
