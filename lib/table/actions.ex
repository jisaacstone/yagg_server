alias Yagg.Board.Unit
alias Yagg.{Event, Board}
alias Yagg.Table.Player
defmodule Yagg.Table.Actions do
  alias __MODULE__

  # Action Types
  defmodule Join do
    @enforce_keys [:player]
    defstruct @enforce_keys

    def resolve(%{player: ""}, _game, _) do
      {:err, :noname}
    end
    def resolve(%{player: player_name}, %{board: :nil} = game, :notfound) do
      case game.players do
        [] -> {
            %{game | players: [Player.new(player_name, :north)]},
            [Event.new(:player_joined, name: player_name, position: :north)]
          }
        [p1] -> 
          p2 = Player.new(player_name, Player.opposite(p1.position))
          # start game implicitly when two players join
          {game, events} = Actions.initial_setup(%{game | players: [p1, p2]})
          {
            game,
            [Event.new(:player_joined, name: player_name, position: p2.position) | events]
          }
        [_p1, _p2] -> {:err, :game_full}
      end
    end
    def resolve(%{}, _game, %Player{}) do
      {:err, :alreadyjoined}
    end
    def resolve(%{}, _game, _player) do
      {:err, :bad_state}
    end
  end
  defmodule Leave do
    defstruct []

    def resolve(%{}, game, %Player{} = player) do
      case Enum.find_index(game.players, fn(p) -> p.name == player.name end) do
        :nil ->
          {[], game}
        index ->
          {
            [Event.new(:player_left, player: player.position, name: player.name)],
            %{game | players: List.delete_at(game.players, index)}
          }
      end
    end
    def resolve(%{}, game, :notfound) do
      {[], game}
    end
  end

  defmodule Ready do
    defstruct []

    def resolve(%{}, game, %{position: pos}) do
      opp = Enum.find_value(game.players, fn(p) -> if p.position != pos, do: p.position end)
      case IO.inspect({opp, game.ready, game.state}) do
        {:nil, _, :open} ->
          {:err, :notenoughplayers}
        {position, position, :open} ->
          {notifications, game} = Actions.initial_setup(game)
          {%{game | state: :placement, ready: :nil}, notifications}
        {_, _, :open} ->
          {
            %{game | ready: pos},
            [Event.new(:player_ready, %{player: opp})]
          }
        {position, position, :placement} ->
          {notifications, game} = Actions.start_battle(game)
          {%{game | ready: :nil}, notifications}
        {_, _, :placement} ->
          {
            %{game | ready: pos},
            [Event.new(:player_ready, %{player: opp})]
          }
      end
    end
  end


  def initial_setup(%{players: players} = game) do
    board = Board.new()
    events = Enum.map(board.grid, fn({{x, y}, feature}) -> Event.new(:feature, %{x: x, y: y, feature: feature}) end)
    {board, events} = Enum.reduce(
      players,
      {board, events},
      fn(player, {board, notifications}) ->
        {hand, notif} = create_hand(player.position, notifications)
        {%{board | hands: Map.put(board.hands, player.position, hand)}, notif}
      end
    )
    {
      %{game | board: board},
      [Event.new(:game_started) | events]
    }
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

  def start_battle(game) do
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

  def resolve(%{__struct__: mod} = action, game, player) do
    mod.resolve(action, game, player)
  end
end
