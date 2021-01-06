alias Yagg.Table.Player
alias Yagg.Table.Action
alias Yagg.Event
alias Yagg.Board.Configuration

defmodule Yagg.Table.Action.Join do
  defstruct []
  @behaviour Action

  @impl Action
  def resolve(_, %{board: %{state: :open}} = table, player) do
    join(table, player, Player.by_id(table, player.id))
  end
  def resolve(_, %{board: :nil} = table, player) do
    join(table, player, Player.by_id(table, player.id))
  end
  def resolve(_, _, _) do
    {:err, :badstate}
  end

  defp join(%{players: []} = table, player, :notfound) do
    {
      %{table | players: [{:north, player}]},
      [Event.PlayerJoined.new(player: player, position: :north)]
    }
  end
  defp join(%{players: [{p1pos, _p1}]} = table, player, :notfound) do
    position = Player.opposite(p1pos)
    # start game implicitly when two players join
    {board, events} = Configuration.setup(table.configuration, table.board)
    {
      %{table | players: [{position, player} | table.players], board: board},
      [Event.PlayerJoined.new(player: player, position: position) | events]
    }
  end
  defp join(%{players: [_p1, _p2 | []]}, _, _) do
    {:err, :table_full}
  end
  defp join(%{}, _table, {_, %Player{}}) do
    {:err, :alreadyjoined}
  end
  defp join(_, _table, _player) do
    {:err, :bad_state}
  end
end
