alias Yagg.Board
alias Yagg.Board.Unit

defmodule Yagg.Board.Actions.Ability do
  @enforce_keys [:name, :x, :y]
  defstruct [:params | @enforce_keys]
  alias __MODULE__

  def resolve(data, %Board{state: :battle} = board, position) do
    module = Module.safe_concat(Ability, String.capitalize(data.name))
    ability = struct!(module, data.params || [])
    coords = {data.x, data.y}
    case ability_at(board, ability, coords) do
      {:err, _} = err -> err
      unit -> module.resolve(ability, board, unit: unit, position: position, coords: coords)
    end
  end

  defp ability_at(board, %{__struct__: struct}, coords) do
    case board.grid[coords] do
      %Unit{ability: ^struct} = unit -> unit
      %Unit{} -> {:err, :unable}
      _ -> {:err, :empty}
    end
  end

  defmodule Selfdestruct do
    defstruct []

    def resolve(_selfdestuct, board, opts) do
      {board, events} = Board.unit_death(board, opts[:unit], opts[:coords])
      {x, y} = opts[:coords]
      surround = [{x + 1, y}, {x - 1, y}, {x, y + 1}, {x, y - 1}]
      Enum.reduce(surround, {board, events}, fn (co, {b, e}) -> killunit(board.grid[co], co, b, e) end)
    end

    defp killunit(%Unit{} = unit, coords, board, events) do
      {board, newevents} = Board.unit_death(board, unit, coords)
      {board, newevents ++ events}
    end
    defp killunit(_, _, board, events) do
      {board, events}
    end
  end
end
