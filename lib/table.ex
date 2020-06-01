alias Yagg.{Event, Board}
alias Yagg.Table.Player
alias Yagg.Board.State

defmodule Yagg.Table do
  use GenServer
  alias __MODULE__

  @enforce_keys [:players, :board, :turn, :configuration]
  @derive {Poison.Encoder, only: [:players, :board, :turn, :configuration]}
  defstruct [:subscribors | @enforce_keys]

  @type t() :: %Table{
    players: [Player.t],
    board: :nil | Board.t,
    turn: :nil | Player.position(),
    configuration: module(),
  }

  def start_link([table]) do
    GenServer.start_link(__MODULE__, table)
  end

  def get(gid) do
    # will be a lookup by id eventually
    pid = gid |> to_charlist() |> :erlang.list_to_pid
    case Process.alive?(pid) do
      :true -> {:ok, pid}
      :false -> {:err, :process_ended}
    end
  end

  def new(configuration \\ Board.Configuration.Default) do
    # For now just one game all the time
    table = %Table{
      players: [],
      subscribors: [],
      board: :nil,
      turn: :nil,
      configuration: configuration,
    }
    case Supervisor.which_children(Yagg.TableSupervisor) do
      [{_id, pid, :worker, _modules} | _] -> {:ok, pid}
      [] -> DynamicSupervisor.start_child(Yagg.TableSupervisor, {Yagg.Table, [table]})
    end
  end

  # API

  def get_state(_gid) do
    {:ok, pid} = new()
    GenServer.call(pid, :get_state)
  end

  def get_player_state(_gid, player_name) do
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

  def table_action(_gid, player_name, action) do
    {:ok, pid} = new()
    GenServer.call(pid, {:table_action, player_name, action})
  end

  def board_action(_gid, player_name, action) do
    {:ok, pid} = new()
    GenServer.call(pid, {:board_action, player_name, action})
  end

  # Callbacks

  def init(%Table{} = table) do
    {:ok, table}
  end

  def handle_call(:get_state, _from, game) do
    {:reply, {:ok, game}, game}
  end
  def handle_call({:subscribe, player}, {pid, _tag}, %{subscribors: subs} = game) do
    {:reply, :ok, %{game | subscribors: [{player, pid} | subs]}}
  end

  def handle_call({:table_action, player_name, action}, _from, game) do
    player = Player.by_name(game, player_name)
    try do
      case Yagg.Table.Action.resolve(action, game, player) do
        {:err, _} = err -> {:reply, err, game}
        {game, events} ->
          notify(game, events)
          {:reply, :ok, game}
      end
    rescue
      FunctionClauseError -> {:reply, {:err, :invalid_or_unknown}, game}
    end
  end

  def handle_call({:board_action, player_name, action}, _from, game) do
    player = Player.by_name(game, player_name)
    # try do
      cond do
        player == :notfound -> {:reply, {:err, :player_invalid}, game}
        game.board.state == :battle and game.turn != player.position -> {:reply, {:err, :notyourturn}, game}
        :true ->
          case Board.Action.resolve(action, game.board, player.position) do
            {:err, _} = err -> {:reply, err, game}
            {board, events} ->
              # One action per turn. Successful move == next turn
              game = %{game | board: board} |> nxtrn()
              notify(game, [Event.new(:turn, %{player: game.turn}) | events])
              {:reply, :ok, game}
          end
      end
    # rescue
      # FunctionClauseError -> {:reply, {:err, :invalid_or_unknown}, game}
    # end
  end

  def handle_call(msg, _from, state) do
    {:reply, {:err, {:unknown_msg, msg}}, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, reason}, %Table{players: players} = game) do
    case Enum.find(players, fn p -> elem(p, 1) == pid end) do
      :nil -> {:noreply, game}
      {name, _} -> 
        :ok = notify(game, Event.new(:player_disconnect, %{player: name, reason: reason}))
        subs =  Enum.reject(game.subscribors, fn({_, ^pid}) -> :true; (_) -> :false end)
        {:noreply, %{game | subscribors: subs}}
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

  defp nxtrn(%Table{board: %Board{state: %State.Placement{}}} = game), do: game
  defp nxtrn(%Table{turn: :north} = game), do: %{game | turn: :south}
  defp nxtrn(%Table{turn: :south} = game), do: %{game | turn: :north}
  defp nxtrn(%Table{turn: :nil} = game), do: %{game | turn: :north}
end
