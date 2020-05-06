alias Yagg.Game.Board
alias Yagg.Game.Unit
alias Yagg.Game.Player
alias Yagg.Event
defmodule Yagg.Action do
  # TODO: send events instead of collecting them?
  def resolve(%{"action" => "join"}, %{state: :open} = game, player_name) do
    case game.players do
      [] -> {:notify, [Event.new(:player_joined, name: player_name, position: :north)], %{game | players: [Player.new(player_name, :north)]}}
      [p1] -> {:notify, [Event.new(:player_joined, name: player_name, position: :south)], %{game | players: [p1, Player.new(player_name, :south)]}}
      [_p1, _p2] -> {:err, :game_full}
    end
  end
  def resolve(%{"action" => "join"}, _game, _player) do
    {:err, :bad_state}
  end

  def resolve(%{"action" => "leave"}, game, player_name) do
    case Enum.find_index(game.players, fn(p) -> p.name == player_name end) do
      :nil -> {:nonotify, game}
      index -> {:notify, [Event.new(:player_left, name: player_name)], %{game | players: List.delete_at(game.players, index)}}
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

  # TODO: fix this mess
  defp initial_setup(%{players: players} = game) do
    {board, notifications} = Enum.reduce(
      players,
      {Board.new(), []},
      fn(player, {board, notifications}) ->
        {b, _p, _i, n} = Enum.zip(
          Player.starting_squares(player, board),
          Unit.starting_units(player)
        ) |> Enum.reduce({board, player, 0, notifications}, &place_unit/2)
        {b, n}
      end
    )
    {notifications, %{game | board: board}}
  end

  defp place_unit({{x, y}, unit}, {board, player, index, notifications}) do
    id = "#{player.position}-#{index}"
    {:ok, board} = Board.place(board, id, x, y)
    board = %{board | units: Map.put(board.units, id, unit)}
    notifications = [
      Event.new(player.position, :new_unit, %{unit: unit, id: id}),
      Event.new(:global, :unit_placed, %{x: x, y: y, id: id})
      | notifications]
    {board, player, index + 1, notifications}
  end
end
