alias Yagg.Game.{Board, Unit, Player}
alias Yagg.{Event, Game}
defmodule Yagg.Action do
  alias __MODULE__

  # Action Types
  defmodule Join do
    @enforce_keys [:player]
    defstruct @enforce_keys
  end
  defmodule Leave do
    defstruct []
  end
  defmodule Ready do
    defstruct []
  end
  defmodule Move do
    @enforce_keys [:from_x, :from_y, :to_x, :to_y]
    defstruct @enforce_keys
  end
  defmodule Place do
    @enforce_keys [:index, :x, :y]
    defstruct @enforce_keys
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
      :nil ->
        {:nonotify, game}
      index ->
        {
          :notify,
          [Event.new(:player_left, player: player.position, name: player.name)],
          %{game | players: List.delete_at(game.players, index)}
        }
    end
  end
  def resolve(%Action.Leave{}, game, :notfound) do
    {:nonotify, game}
  end

  def resolve(%Action.Ready{}, game, %{position: pos}) do
    opp = Enum.find_value(game.players, fn(p) -> if p.position != pos, do: p.position end)
    IO.inspect(case IO.inspect({opp, game.ready, game.state}) do
      {:nil, _, :open} ->
        {:err, :notenoughplayers}
      {position, position, :open} ->
        {notifications, game} = initial_setup(game)
        {:notify,  notifications, %{game | state: :placement, ready: :nil}}
      {_, _, :open} ->
        {:notify, [Event.new(:player_ready, %{player: opp})], %{game | ready: pos}}
      {position, position, :placement} ->
        {notifications, game} = start_battle(game)
        {:notify, notifications, %{game | ready: :nil}}
      {_, _, :placement} ->
        {:notify, [Event.new(:player_ready, %{player: opp})], %{game | ready: pos}}
    end)
  end

  def resolve(%Action.Move{} = move, %Game{turn: position} = game, %Player{position: position}) do
    case Board.move(game.board, position, {move.from_x, move.from_y}, {move.to_x, move.to_y}) do
      {:err, _} = err ->
        err
      {:ok, board, events} ->
        game = nxtrn(%{game | board: board})
        events = [Event.new(:turn, %{player: game.turn}) | events]
        {:notify, events, game}
      {:gameover, board, events} ->
        {:notify, events, %{game | board: board, state: :over, turn: :nil}}
    end
  end
  def resolve(%Action.Move{}, _game, %Player{}) do
    {:err, :notyourturn}
  end

  def resolve(%Action.Place{} = act, %Game{state: :placement} = game, %Player{position: position}) do
    case Board.assign(game.board, position, act.index, {act.x, act.y}) do
      {:ok, board} -> 
        {
          :notify,
          [Event.new(position, :unit_assigned, %{index: act.index, x: act.x, y: act.y})],
          %{game | board: board}
        }
      err -> err
    end
  end

  # catchall  
  def resolve(action, _game, _player) do
    IO.inspect({:err, %{unknown: action}})
  end

  # Private functions
  #
  defp nxtrn(%Game{turn: :north} = game), do: %{game | turn: :south}
  defp nxtrn(%Game{turn: :south} = game), do: %{game | turn: :north}

  defp initial_setup(%{players: players} = game) do
    {board, notifications} = Enum.reduce(
      players,
      {Board.new(), []},
      fn(player, {board, notifications}) ->
        {hand, notif} = create_hand(player.position, notifications)
        {%{board | hands: Map.put(board.hands, player.position, hand)}, notif}
      end
    )
    {[Event.new(:game_started) | notifications], %{game | board: board, state: :placement}}
  end

  defp create_hand(position, notifications) do
    {_, hand, notif} = Enum.reduce(
      Unit.starting_units(position),
      {0, %{}, notifications},
      fn (unit, {i, h, n}) ->
        {
          i + 1,
          Map.put_new(h, i, {unit, :nil}),
          [Event.new(unit.position, :new_hand, %{unit: unit, index: i}) | n]
        }
      end
    )
    {hand, notif}
  end

  defp place_hand(board, hand) do
    Enum.reduce(
      hand,
      board,
      fn({_, {unit, {x, y}}}, board) -> Board.place!(board, unit, {x, y})
        (index, {unit, _}) -> throw({:err, :unassigned, unit.position, index})
      end
    )
  end

  defp start_battle(game) do
    try do
      board = game.board
        |> place_hand(game.board.hands[:north])
        |> place_hand(game.board.hands[:south])
        |> Map.put(:hands, %{north: %{}, south: %{}})

      notifications = Enum.reduce(
        board.grid,
        [],
        fn
          ({{x, y}, %Unit{} = unit}, nfcns) ->
            [Event.new(:global, :unit_placed, %{x: x, y: y, player: unit.position}) | nfcns]
          (_, nfcns) -> nfcns
        end
      )
      game = %{game | state: :battle, board: board}
      {[Event.new(:battle_started) | notifications], game}
    catch
      err -> err
    end
  end
end
