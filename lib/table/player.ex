alias Yagg.Table

defmodule Table.Player do
  alias __MODULE__
  @derive {Poison.Encoder, only: [:id, :name]}
  @enforce_keys [:id, :name]
  defstruct @enforce_keys

  @type position() :: :north | :south
  @type t() :: %Player{
    id: non_neg_integer,
    name: String.t(),
  }

  def init_db() do
    :ets.new(:players, [:public, :named_table])
  end

  def new(name) do
    id = :erlang.phash2({node(), :erlang.now()})
    player = %Player{id: id, name: name}
    :true = :ets.insert(:players, {id, player})
    player
  end

  def fetch(id) do
    case :ets.lookup(:players, id) do
      [{^id, player}] -> {:ok, player}
      _ -> {:err, :notfound}
    end
  end

  @spec opposite(position) :: position
  def opposite(:north), do: :south
  def opposite(:south), do: :north

  @spec by_id(Table.t, non_neg_integer) :: {position, t} | :notfound
  def by_id(game, id) do
    case game.players do
      [{_, %Player{id: ^id}} = player | _] -> player
      [_, {_, %Player{id: ^id}} = player | _] -> player
      _ -> :notfound
    end
  end

  @spec remove(Table.t, t) :: Table.t
  def remove(%{players: players} = table, player) do
    players = Enum.reject(players, fn ({_, p}) -> p.id == player.id end)
    %{table | players: players}
  end

end
