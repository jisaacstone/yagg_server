alias Yagg.Table
alias Yagg.Event
alias Yagg.Table.Player

defmodule Table.Action.Leave do
  defstruct []
  @behaviour Table.Action

  @impl Table.Action
  def resolve(%{}, table, %{id: id}) do
    case Player.by_id(table, id) do
      :notfound ->
        {[], table}
      {position, player} ->
        case Player.remove(table, player) do
          %{players: []} -> :shutdown_table
          table -> {table, [Event.new(:player_left, player: position, name: player.name)]}
        end
    end
  end
end
