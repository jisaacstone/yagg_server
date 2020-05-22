alias Yagg.Action
alias Yagg.Board
alias Yagg.Unit
alias Yagg.Event
alias Yagg.Table.Player

defmodule Yagg.Board.Actions.Ability do
  @enforce_keys [:name, :x, :y]
  defstruct [:params | @enforce_keys]
  alias __MODULE__

  def resolve(data, %Board{state: :battle} = board, _position) do
    module = Module.safe_concat(Ability, String.capitalize(data.name))
    ability = struct!(module, data.params || [])
    coords = {data.x, data.y}
    case ability_at(board, ability, coords) do
      {:err, _} = err -> err
      unit -> module.resolve(ability, board, unit: unit, coords: coords)
    end
  end

  defp ability_at(board, %{__struct__: struct}, coords) do
    case board.grid[coords] do
      %Unit{ability: ^struct} = unit -> unit
      %Unit{} -> {:err, :unable}
      _ -> {:err, :empty}
    end
  end

  defmodule NOOP do
    use Action

    def resolve(_, board, _) do
      {board, []}
    end
  end

  defmodule Selfdestruct do
    use Action

    def resolve(_selfdestuct, board, opts) do
      surround = Board.features_around(board, opts[:coords])
      Enum.reduce(surround, {board, []}, &killunit/2)
    end

    defp killunit({coords, %Unit{} = unit}, {board, events}) do
      {board, newevents} = Board.unit_death(board, unit, coords)
      {board, newevents ++ events}
    end
    defp killunit(_, state) do
      state
    end
  end

  defmodule Lose do
    use Action

    def resolve(_, board, opts) do
      IO.inspect({
        %{board | state: :gameover},
        [Event.new(:gameover, %{winner: Player.opposite(opts[:unit].position)})]
      })
    end
  end
end
