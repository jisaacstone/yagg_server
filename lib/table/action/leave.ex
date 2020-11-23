alias Yagg.Table
alias Yagg.Event
alias Yagg.Table.Player

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
    board = %{table.board | state: :gameover}
    {%{table | board: board}, [Event.Gameover.new(winner: Player.opposite(position))]}
  end
  defp maybe_set_state(table, _), do: {table, []}
end
