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
        {
          Player.remove(table, player),
          [Event.new(:player_left, player: position, name: player.name)],
        }
    end
  end
end
