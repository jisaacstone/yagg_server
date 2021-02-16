alias Yagg.Unit
alias Yagg.Board
alias Yagg.Board.Grid
alias Yagg.Table.Player

defmodule Unit.Glosto do
  @behaviour Unit

  @impl Unit
  def new(position) do
    Unit.new(
      name: :glosto,
      attack: 7,
      defense: 0,
      ability: Unit.Glosto.Rampage,
      position: position
    )
  end

  defmodule Rampage do
    @moduledoc """
    Move forward one square. Attack surrounding squares. Move back. Attack left and right.
    """
    use Unit.Ability

    @impl Unit.Ability
    def resolve(board, opts) do
      from = opts[:coords]
      position = opts[:unit].position
      directions = %{
        front: Grid.cardinal(position, :front),
        left: Grid.cardinal(position, :left),
        right: Grid.cardinal(position, :right)
      }
      case Board.move(board, position, from, Grid.next(directions.front, from)) do
        {:err, _} -> {board, []}
        {board, events} -> first_attacks(board, opts[:unit], from, directions, events)
      end
    end

    defp first_attacks(board, %{position: position} = unit, from, directions, events) do
      mid = Grid.next(directions.front, from)
      case attack(board, mid, directions.left, unit, events) do
        {:end, {board, events}} -> {board, events}
        {:continue, {board, events}} ->
          case attack(board, mid, directions.front, unit, events) do
            {:end, {board, events}} -> {board, events}
            {:continue, {board, events}} ->
              case attack(board, mid, directions.right, unit, events) do
                {:end, {board, events}} -> {board, events}
                {:continue, {board, events}} ->
                  case Board.move(board, position, mid, from) do
                    {:err, _} -> {board, events}
                    {board, e2} -> second_attacks(board, unit, from, directions, events ++ e2)
                  end
              end
          end
      end
    end

    defp second_attacks(board, unit, coord, directions, events) do
      case attack(board, coord, directions.left, unit, events) do
        {:end, {board, events}} -> {board, events}
        {:continue, {board, events}} ->
          case attack(board, coord, directions.right, unit, events) do
            {:end, {board, events}} -> {board, events}
            {:continue, {board, events}} -> {board, events}
          end
      end
    end

    defp attack(board, coord, direction, unit, events) do
      enemy = Player.opposite(unit.position)
      to = Grid.next(direction, coord)
      case Grid.thing_at(board, to) do
        %Unit{position: ^enemy} = opponent ->
          {board, e2} = Board.do_battle(board, unit, opponent, coord, to, no_move: :true)
          case Grid.thing_at(board, coord) do
            %{name: :glosto} -> {:continue, {board, events ++ e2}}
            _ -> {:end, {board, events ++ e2}}
          end
        _ -> {:continue, {board, events}}
      end
    end
  end

end
