alias Yagg.Table
alias Yagg.Event
alias Yagg.Table.Player
alias Yagg.Board
alias Yagg.Board.Grid
alias Yagg.Jobfair

defmodule Table.Action.Leave do
  defstruct []
  @behaviour Table.Action

  @impl Table.Action
  def resolve(%{}, table, %{id: id}) do
    leave(table, Player.by_id(table, id))
  end

  defp leave(table, :notfound) do
    {[], table}
  end
  defp leave(%{players: [{position, player}]}, {position, player}) do
    :shutdown_table
  end
  defp leave(table, {position, player}) do
    {table, events} = Player.remove(table, player) |> maybe_set_state(position)
    events = [Event.new(:player_left, player: position, name: player.name) | events]
    {table, events}
  end

  defp maybe_set_state(%{board: %{state: s}} = table, position) when s != :gameover do
    {grid, events} = Grid.reveal_units(table.board.grid)
    Table.gameover(table, %{table.board | grid: grid}, Player.opposite(position), "opponent left", events)
  end
  defp maybe_set_state(%{board: %Jobfair{}} = table, position) do
    board = Board.new(table.configuration)
    Table.gameover(table, board, Player.opposite(position), "opponent left")
  end
  defp maybe_set_state(table, _), do: {table, []}

end
