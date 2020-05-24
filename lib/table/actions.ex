alias Yagg.{Event, Board}
alias Yagg.Table.Player
defmodule Yagg.Table.Actions do
  alias __MODULE__

  defmodule Join do
    @enforce_keys [:player]
    defstruct @enforce_keys

    def resolve(%{player: ""}, _table, _) do
      {:err, :noname}
    end
    def resolve(%{player: player_name}, %{board: :nil} = table, :notfound) do
      case table.players do
        [] -> {
            %{table | players: [Player.new(player_name, :north)]},
            [Event.new(:player_joined, name: player_name, position: :north)]
          }
        [p1] -> 
          p2 = Player.new(player_name, Player.opposite(p1.position))
          # start game implicitly when two players join
          {table, events} = Actions.initial_setup(%{table | players: [p1, p2]})
          {
            table,
            [Event.new(:player_joined, name: player_name, position: p2.position) | events]
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

  defmodule Restart do
    defstruct []

    def resolve(%{}, %{players: [_, _]} = table, %Player{}) do
      Actions.initial_setup(table)
    end
  end

  def resolve(%{__struct__: mod} = action, game, player) do
    mod.resolve(action, game, player)
  end

  def initial_setup(table) do
    {board, events} = Board.new() |> Board.setup()
    {%{table | board: board}, events}
  end
end
