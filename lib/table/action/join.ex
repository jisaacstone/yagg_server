alias Yagg.Table.Player
alias Yagg.Table.Action
alias Yagg.Event

defmodule Yagg.Table.Action.Join do
  defstruct [:player]
  @behaviour Action

  @impl Action
  def resolve(%{player: ""}, _table, _) do
    {:err, :noname}
  end
  def resolve(%{player: player_name}, %{board: :nil} = table, :notfound) do
    case table.players do
      [] -> {
          %{table | players: [Player.new(player_name, :north)]},
          [Event.PlayerJoined.new(name: player_name, position: :north)]
        }
      [p1] -> 
        p2 = Player.new(player_name, Player.opposite(p1.position))
        # start game implicitly when two players join
        {table, events} = Action.initial_setup(%{table | players: [p1, p2]})
        {
          table,
          [Event.PlayerJoined.new(name: player_name, position: p2.position) | events]
        }
      [_p1, _p2] -> {:err, :table_full}
    end
  end
  def resolve(%{}, _table, %Player{}) do
    {:err, :alreadyjoined}
  end
  def resolve(%{}, _table, _player) do
    {:err, :bad_state}
  end
end
