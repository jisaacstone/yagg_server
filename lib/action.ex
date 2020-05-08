alias Yagg.Game.{Board, Unit, Player}
alias Yagg.Event
defmodule Yagg.Action do
  alias __MODULE__
  defmodule Join do
    defstruct [
      player: "",
    ]
  end
  defmodule Leave do
    defstruct []
  end
  defmodule Start do
    defstruct []
  end
  defmodule Move do
    defstruct [
      id: "",
      to_x: 0,
      to_y: 0,
    ]
  end
  def resolve(%Action.Join{player: player_name}, %{state: :open} = game, :notfound) do
    case game.players do
      [] -> {:notify, [Event.new(:player_joined, name: player_name, position: :north)], %{game | players: [Player.new(player_name, :north)]}}
      [p1] -> {:notify, [Event.new(:player_joined, name: player_name, position: :south)], %{game | players: [p1, Player.new(player_name, :south)]}}
      [_p1, _p2] -> {:err, :game_full}
    end
  end
  def resolve(%Action.Join{}, _game, %Player{}) do
    {:err, :alreadyjoined}
  end
  def resolve(%Action.Join{}, _game, _player) do
    {:err, :bad_state}
  end

  def resolve(%Action.Leave{}, game, %Player{} = player) do
    case Enum.find_index(game.players, fn(p) -> p.name == player.name end) do
      :nil -> {:nonotify, game}
      index -> {:notify, [Event.new(:player_left, name: player.name)], %{game | players: List.delete_at(game.players, index)}}
    end
  end
  def resolve(%Action.Leave{}, game, :notfound) do
    {:nonotify, game}
  end

  def resolve(%Action.Start{}, game, _player) do
    case game.players do
      [_north, _south] ->
        {notifications, game} = initial_setup(game)
        {:notify, [Event.new(:game_started) | notifications], game}
      _other -> {:err, :notenoughplayers}
    end
  end
  # action: move
  def resolve(%Action.Move{id: id, to_x: to_x, to_y: to_y}, game, %Player{position: position}) do
    case game.board.units[id] do
      :nil -> {:err, :nosuchunit}
      %Unit{position: p} when p != position -> {:err, :unowned}
      unit ->
        case Board.move(game.board, unit, to_x, to_y) do
          {:err, _} = err -> err
          {board, events} -> {:notify, events, %{game | board: board}}
        end
    end
  end
  def resolve(%Action.Move{} = move, _game, player) do
    {:err, IO.inspect(%{move: move, player: player})}
  end
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
          Unit.starting_units(player.position)
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
