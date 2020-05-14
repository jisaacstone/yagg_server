alias Yagg.Event
alias Yagg.Game.{Board, Player}

defmodule Yagg.Game do
  use GenServer
  alias __MODULE__  # so we can do %Game{} instead of %Yagg.Game{}

  @enforce_keys [:state, :players, :board, :turn, :ready]
  @derive {Poison.Encoder, only: [:state, :players, :board, :turn, :ready]}
  defstruct [:subscribors | @enforce_keys]

  def start_link(options) do
    GenServer.start_link(__MODULE__, [], options)
  end

  def get(gid) do
    # will be a lookup by id eventually
    pid = gid |> to_charlist() |> :erlang.list_to_pid
    case Process.alive?(pid) do
      :true -> {:ok, pid}
      :false -> {:err, :process_ended}
    end
  end

  def new() do
    # For now just one game all the time
    # TODO: game args
    case Supervisor.which_children(Yagg.GameSupervisor) do
      [{_id, pid, :worker, _modules} | _] -> {:ok, pid}
      [] -> DynamicSupervisor.start_child(Yagg.GameSupervisor, Yagg.Game)
    end
  end

  # API

  def get_state(_gid) do
    {:ok, pid} = new()
    GenServer.call(pid, :get_state)
  end

  def get_units(_gid, player_name) do
    {:ok, pid} = new()
    case GenServer.call(pid, :get_state) do
      {:err, _} = err -> err
      {:ok, game} ->
        case Player.by_name(game, player_name) do
          %Player{position: position} -> Board.units(game.board, position)
          _ -> {:err, :unknown_player}
        end
    end
  end

  def subscribe(_gid, player) do
    {:ok, pid} = new()
    Process.monitor(pid)
    GenServer.call(pid, {:subscribe, player})
    {:ok, pid}
  end

  def act(_gid, player_name, action) do
    {:ok, pid} = new()
    GenServer.call(pid, {:act, player_name, action})
  end

  # Callbacks

  def init(_) do
    {:ok, %Game{
      state: :open,
      players: [],
      subscribors: [],
      board: Board.new(),
      turn: :north,
      ready: :nil,
    }}
  end
  def handle_call(:get_state, _from, game) do
    {:reply, {:ok, game}, game}
  end
  def handle_call({:subscribe, player}, {pid, _tag}, %{subscribors: subs} = game) do
    {:reply, :ok, %{game | subscribors: [{player, pid} | subs]}}
  end
  def handle_call({:act, player_name, action}, _from, game) do
    player = Player.by_name(game, player_name)
    case Yagg.Action.resolve(action, game, player) do
      {:err, _} = err -> {:reply, err, game}
      {:notify, event, game} ->
        notify(game, event)
        {:reply, :ok, game}
      {:nonotify, game} -> {:reply, :ok, game}
    end
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

  # Private

  # TODO: Event types, move to another module?
  defp notify(_game, []) do
    :ok
  end
  defp notify(game, [event | events]) do
    notify(game, event)
    notify(game, events)
  end
  defp notify(%{subscribors: subs, players: players}, %Event{} = event) do
    Enum.each(
      subs,
      fn({player, pid}) ->
        case event.stream do
          :global ->
            send(pid, event)
          stream ->
            if Enum.any?(players, fn(p) -> p.name == player and p.position == stream end) do
              send(pid, event)
            end
        end
      end
    )
  end
end
