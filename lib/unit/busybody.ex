alias Yagg.Unit
alias Yagg.Board
alias Yagg.Event
alias Yagg.Board.Grid
alias Yagg.Board.Action.Ability

defmodule Unit.Busybody do
  @behaviour Unit
  @impl Unit
  def new(position) do
    Unit.new(
      position,
      :busybody,
      3,
      6,
      Unit.Busybody.Spin
    )
  end

  defmodule Spin do
    @moduledoc """
    Everything in adjacent squares is rotated clockwise.
    Anything that ends up off the edge of the board is destroyed.
    """
    use Ability
    @impl Ability
    def resolve(board, opts) do
      {board, things} = gather(board, opts[:coords], [:north, :east, :south, :west, :north], [])
      place(board, things, [], [])
    end

    # one extra so hd() below works
    defp gather(board, _, [:north], things), do: {board, things}
    defp gather(board, coord, [direction | directions], things) do
      from = Grid.next(direction, coord)
      case Map.pop(board.grid, from) do
        {:nil, _} -> gather(board, coord, directions, things)
        {thing, grid} ->
          to = Grid.next(hd(directions), coord)
          gather(%{board | grid: grid}, coord, directions, [{from, to, thing} | things])
      end
    end

    defp place(board, [], effects, events) do
      {board, events ++ [Event.Multi.new(events: effects)]}
    end
    defp place(board, [{from, to, thing} | things], effects, events) do
      case Grid.thing_at(board, to) do
        :out_of_bounds ->
          {board, evts} = offscreend(board, thing, from)
          place(board, things, effects, evts ++ events)
        :nil ->
          effects = [Event.ThingMoved.new(thing, from: from, to: to) | effects]
          board = %{board | grid: Map.put(board.grid, to, thing)}
          place(board, things, effects, events)
      end
    end

    defp offscreend(board, %{visible: :none}, _coord) do
      {board, []}
    end
    defp offscreend(board, %Unit{} = unit, coord) do
      Board.unit_death(board, coord, unit: unit)
    end
    defp offscreend(board, _feature, coord) do
      event = Event.ThingMoved.new(from: coord, to: :offscreen)
      {board, [event]}
    end
  end
end
