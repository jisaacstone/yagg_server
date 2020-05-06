alias Yagg.Game.Board
alias Yagg.Game.Unit
alias Yagg.Game.Player
alias Yagg.Event
defmodule Yagg.Action do
  # TODO: send events instead of collecting them?
  def resolve(%{"action" => "join"}, %{state: :open} = game, player_name) do
    case game.players do
      [] -> {:notify, [Event.new(:player_joined, player: player_name)], %{game | players: [Player.new(player_name, :north)]}}
      [p1] -> {:notify, [Event.new(:player_joined, player: player_name)], %{game | players: [p1, Player.new(player_name, :south)]}}
      [_p1, _p2] -> {:err, :game_full}
    end
  end
  def resolve(%{"action" => "join"}, _game, _player) do
    {:err, :bad_state}
  end

  def resolve(%{"action" => "leave"}, game, player_name) do
    case Enum.find_index(game.players, fn(p) -> p.name == player_name end) do
      :nil -> {:nonotify, game}
      index -> {:notify, [Event.new(:player_left, player: player_name)], %{game | players: List.delete_at(game.players, index)}}
    end
  end

  def resolve(%{"action" => "start"}, game, _player) do
    case game.players do
      [_north, _south] ->
        {notifications, game} = initial_setup(game)
        {:notify, [Event.new(:game_started) | notifications], game}
      _other -> {:err, :notenoughplayers}
    end
  end
  # action: move
      
  def resolve(action, _game, _player) do
    {:err, %{unknown: action}}
  end

  defp initial_setup(%{players: players} = game) do
    {board, notifications} = Enum.reduce(
      players,
      {Board.new(), []},
      fn(player, {board, notifications}) ->
        {b, _p, n} = Enum.zip(
          Player.starting_squares(player, board),
          Unit.starting_units(player)
        ) |> Enum.reduce({board, player, notifications}, &place_unit/2)
        {b, n}
      end
    )
    {notifications, %{game | board: board}}
  end

  defp place_unit({{x, y}, unit}, {board, player, notifications}) do
    {:ok, board} = Board.place(board, unit, x, y)
    notifications = [
      Event.new(player.position, :new_unit, %{unit: unit, x: x, y: y}),
      Event.new(:global, :unit_placed, %{x: x, y: y})
      | notifications]
    {board, player, notifications}
  end
end
