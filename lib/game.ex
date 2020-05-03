defmodule YaggServer.Game do
  use GenServer
  alias __MODULE__  # so we can do %Game{} instead of %YaggServer.Game{}

  @enforce_keys [:state, :players]
  defstruct state: :open, players: []

  @type game_state :: :open | :place | :battle | :end
  @type t :: %__MODULE__{
    state: game_state,
    players: List.t
  }

  def start_link(options) do
    GenServer.start_link(__MODULE__, [], options)
  end

  def init(_) do
    {:ok, %Game{state: :open, players: []}}
  end

  def handle_call({:join, player}, {pid, _tag}, %Game{state: :open} = game) do
    _ref = Process.monitor(pid)
    :ok = notify(game, %{event: :player_joined, player: player})
    {:reply, :ok, %{game | players: [{player, pid} | game.players]}}
  end
  def handle_call({:join, _player}, _from, game) do
    {:reply, {:err, :bad_state}, game}
  end

  def handle_call(:start, _from, %Game{players: []} = game) do
    {:reply, {:err, :no_players}, game}
  end
  def handle_call(:start, _from, %Game{state: :open} = game) do
    :ok = notify(game, %{event: :game_started})
    {:reply, :ok, %{game | state: :place}}
  end

  def handle_call(:end, _from, %Game{state: :started} = game) do
    :ok = notify(game, %{event: :game_ended})
    {:reply, :ok, %{game | state: :end}}
  end
  def handle_call(:end, _from, game) do
    {:reply, {:err, :bad_state}, game}
  end

  def handle_call(msg, _from, state) do
    {:reply, {:err, {:unknown_msg, msg}}, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, reason}, %Game{players: players} = game) do
    case Enum.find(players, fn p -> elem(p, 1) == pid end) do
      :nil -> {:noreply, game}
      {name, _} -> 
        :ok = notify(game, %{event: :player_disconnect, player: name, reason: reason})
        {:noreply, game}
    end
  end
  def handle_info(other, game) do
    IO.inspect([unexpected_info: other])
    {:noreply, game}
  end

  def get(gid) do
    # will be a lookup by id eventually
    pid = gid |> to_charlist() |> :erlang.list_to_pid
    case Process.alive?(pid) do
      :true -> {:ok, pid}
      :false -> {:err, :process_ended}
    end
  end

  # TODO: Event types, move to another module?
  defp notify(%{players: players}, message) do
    IO.inspect([notify: message])
    Enum.each(players, fn({_player, pid}) -> send(pid, message) end)
  end
end
