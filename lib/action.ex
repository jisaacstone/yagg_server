defmodule YaggServer.Action do
  def resolve(%{"action" => "join"}, %{state: :open} = game, player) do
    case game.players do
      [] -> {:nonotify, %{game | players: [player]}}
      [p1] -> {:notify, %{game | players: [p1, player]}, %{event: :player_joined, player: player}}
      _ -> {:err, :game_full}
    end
  end
  def resolve(%{"action" => "join"}, _game, _player) do
    {:err, :bad_state}
  end
  def resolve(action, _game, _player) do
    {:err, :unknown, action}
  end

  # TODO: move to Action
# #   def handle_call({:join, player}, {pid, _tag}, %Game{state:V :open} = game) do
# #     _ref = Process.monitor(pid)
# #     :ok = notify(game, %{event: :player_joined, player: player})
# #     {:reply, :ok, %{game | players: [{player, pid} | game.players]}}
# #   end
# #   def handle_call({:join, _player}, _from, game) do
# #     {:reply, {:err, :bad_state}, game}
# #   end
# #   def handle_call(:start, _from, %Game{players: []} = game) do
# #     {:reply, {:err, :no_players}, game}
# #   end
# #   def handle_call(:start, _from, %Game{state: :open} = game) do
# #     :ok = notify(game, %{event: :game_started})
# #     {:reply, :ok, %{game | state: :place}}
# #   end
# #   def handle_call(:end, _from, %Game{state: :started} = game) do
# #     :ok = notify(game, %{event: :game_ended})
# #     {:reply, :ok, %{game | state: :end}}
# #   end
# #   def handle_call(:end, _from, game) do
# #     {:reply, {:err, :bad_state}, game}
# #   end
  # end TODO
end
