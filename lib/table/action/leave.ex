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
    table = Player.remove(table, player) |> maybe_set_state()
    events = [
      Event.Gameover.new(winner: Player.opposite(position)),
      Event.new(:player_left, player: position, name: player.name)
    ]
    {table, events}
  end

  defp maybe_set_state(%{board: %{state: _}} = table) do
    board = %{table.board | state: :gameover}
    %{table | board: board}
  end
  defp maybe_set_state(table), do: table
end
