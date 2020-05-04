alias Yagg.Game.Board
alias Yagg.Game.Unit
alias Yagg.Game.Player
alias Yagg.Event
defmodule Yagg.Action do
  # TODO: send events instead of collecting them?
  def resolve(%{"action" => "join"}, %{state: :open} = game, player_name) do
    case game.players do
      [] -> {:nonotify, %{game | players: [Player.new(player_name, :north)]}}
      [p1] -> {:notify, %{game | players: [p1, Player.new(player_name, :south)]}, %{event: :player_joined, player: player_name}}
      _ -> {:err, :game_full}
    end
  end
  def resolve(%{"action" => "join"}, _game, _player) do
    {:err, :bad_state}
  end
  def resolve(%{"action" => "start"}, game, _player) do
    case game.players do
      [_north, _south] ->
        {game, notifications} = initial_setup(game)
        {:notify, [Event.new(:game_started) | notifications], game}
      _other -> {:err, :notenoughplayers}
    end
  end
      
  def resolve(action, _game, _player) do
    {:err, :unknown, action}
  end

  defp initial_setup(%{players: players} = game) do
    {board, notifications} = Enum.reduce(
      players,
      {Board.new(), []},
      fn(player, {board, notifications}) ->
        Enum.zip(
          Player.starting_squares(player, board),
          Unit.starting_units()
        ) |> Enum.reduce({board, player, notifications}, &place_unit/2)
      end
    )
    {%{game | board: board}, notifications}
  end

  defp place_unit({{x, y}, unit}, {board, player, notifications}) do
    board = Board.place(board, unit, x, y)
    notifications = [
      Event.new(player.position, :unit_placed, %{unit: unit, x: x, y: y}),
      Event.new(:global, :unit_placed, %{x: x, y: y})
      | notifications]
    {board, player, notifications}
  end
end
