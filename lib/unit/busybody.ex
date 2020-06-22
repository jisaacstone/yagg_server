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
    Anything that ends up off the edge of the board is gone.
    """
    use Ability
    @impl Ability
    def resolve(board, opts) do
      {board, things} = IO.inspect(gather(board, opts[:coords], [:north, :east, :south, :west, :north], []))
      place(board, things, [])
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

    defp place(board, [], events), do: {board, events}
    defp place(board, [{from, to, thing} | things], events) do
      case Grid.thing_at(board, to) do
        :out_of_bounds ->
          {board, evts} = offscreend(board, thing, from)
          place(board, things, evts ++ events)
        :nil ->
          event = Event.ThingMoved.new(from: from, to: to)
          board = %{board | grid: Map.put(board.grid, to, thing)}
          place(board, things, [event | events])
      end
    end

    defp offscreend(board, %Unit{} = unit, coord) do
      Board.unit_death(board, unit, coord)
    end
    defp offscreend(board, _feature, coord) do
      event = Event.ThingMoved.new(from: coord, to: :offscreen)
      {board, [event]}
    end
  end
end
