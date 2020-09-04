alias Yagg.{Event, Board, Jobfair}
alias Yagg.Table.Player
alias Yagg.Board.State
alias Yagg.Board.Configuration

defmodule Yagg.Table do
  use GenServer
  alias __MODULE__

  @enforce_keys [:id, :players, :board, :turn, :configuration]
  @derive {Poison.Encoder, only: [:players, :board, :turn, :configuration]}
  defstruct [:subscribors | @enforce_keys]

  @type id :: String.t
  @type t() :: %Table{
    id: id,
    players: [Player.t],
    board: :nil | Board.t | Jobfair.t,
    turn: :nil | Player.position(),
    configuration: module(),
  }

  def start_link([table]) do
    GenServer.start_link(__MODULE__, table)
  end

  def get(table_id) do
    # will be a lookup by id eventually
    pid = id_to_pid(table_id)
    case Process.alive?(pid) do
      :true -> {:ok, pid}
      :false -> {:err, :process_ended}
    end
  end

  @spec list() :: [pid]
  def list() do
    Supervisor.which_children(Yagg.TableSupervisor)
      |> Enum.map(fn ({_, pid, _, _}) -> pid end)
  end

  @spec new(module) :: {:ok, pid}
  def new(configuration \\ Board.Configuration.Random) do
    table = %Table{
      id: :nil,
      players: [],
      subscribors: [],
      board: Configuration.initial_board(configuration),
      turn: :nil,
      configuration: configuration,
    }
    DynamicSupervisor.start_child(Yagg.TableSupervisor, {Yagg.Table, [table]})
  end

  # TO ENABLE default table
  def single__(configuration \\ Board.Configuration.Random) do
    case Supervisor.which_children(Yagg.TableSupervisor) do
      [{_id, pid, :worker, _modules} | _] -> {:ok, pid}
      [] -> new(configuration)
    end
  end

  def get_or_single__(table_id) do
    try do
      case get(table_id) do
        {:err, _} -> 
          IO.inspect('__single')
          single__()
        {:ok, pid} -> {:ok, pid}
      end
    rescue
      ArgumentError -> single__()
    end
  end
  # END TO ENABLE

  # API

  @spec get_state(pid | id) :: {:ok, t}
  def get_state(pid) when is_pid(pid) do
    GenServer.call(pid, :get_state)
  end
  def get_state(table_id) do
    {:ok, pid} = get_or_single__(table_id)
    GenServer.call(pid, :get_state)
  end

  @spec get_player_state(id, String.t) :: {:ok, %{grid: list, hand: list}} | {:err, atom}
  def get_player_state(table_id, player_name) do
    {:ok, pid} = get_or_single__(table_id)
    case GenServer.call(pid, :get_state) do
      {:err, _} = err -> err
      {:ok, game} ->
        case Player.by_name(game, player_name) do
          %Player{position: position} -> Board.units(game.board, position)
          _ -> {:err, :unknown_player}
        end
    end
  end

  @spec subscribe(id, String.t) :: {:ok, pid}
  def subscribe(table_id, player) do
    {:ok, pid} = get_or_single__(table_id)
    IO.inspect(table: table_id, pid: pid)
    Process.monitor(pid)
    GenServer.call(pid, {:subscribe, player})
    {:ok, pid}
  end

  @spec table_action(id, String.t, struct) :: :ok | {:err, atom}
  def table_action(table_id, player_name, action) do
    {:ok, pid} = get_or_single__(table_id)
    GenServer.call(pid, {:table_action, player_name, action})
  end

  @spec board_action(id, String.t, struct) :: :ok | {:err, atom}
  def board_action(pid, player_name, action) when is_pid(pid) do
    GenServer.call(pid, {:board_action, player_name, action})
  end
  def board_action(table_id, player_name, action) do
    {:ok, pid} = get_or_single__(table_id)
    GenServer.call(pid, {:board_action, player_name, action})
  end

  def pid_to_id(pid) do
    pid |> :erlang.pid_to_list() |> to_string() |> String.split(".") |> tl |> hd
  end

  def id_to_pid(id) do
    "<0.#{id}.0>" |> to_charlist() |> :erlang.list_to_pid
  end

  # Callbacks

  def init(%Table{} = table) do
    id = self() |> pid_to_id()
    {:ok, %{table | id: id}}
  end

  def handle_call(:get_state, _from, game) do
    {:reply, {:ok, game}, game}
  end
  def handle_call({:subscribe, player}, {pid, _tag}, %{subscribors: subs} = game) do
    {:reply, :ok, %{game | subscribors: [{player, pid} | subs]}}
  end

  def handle_call({:table_action, player_name, action}, _from, game) do
    player = Player.by_name(game, player_name)
    # try do
      case Yagg.Table.Action.resolve(action, game, player) do
        {:err, _} = err -> {:reply, err, game}
        {game, events} ->
          notify(game, events)
          {:reply, :ok, game}
      end
    # rescue
    #   FunctionClauseError -> {:reply, {:err, :invalid_or_unknown}, game}
    # end
  end

  def handle_call({:board_action, player_name, action}, _from, game) do
    player = Player.by_name(game, player_name)
    # try do
      cond do
        player == :notfound -> {:reply, {:err, :player_invalid}, game}
        game.board && game.board.state == :battle and game.turn != player.position -> {:reply, {:err, :notyourturn}, game}
        :true ->
          case Board.Action.resolve(action, game.board, player.position) do
            {:err, _} = err -> {:reply, err, game}
            {board, events} ->
              # One action per turn. Successful move == next turn
              game = %{game | board: board}
              {game, events} = if (board.state == :battle) do
                game = nxtrn(game)
                {game, [Event.Turn.new(player: game.turn) | events]}
              else
                {game, events}
              end
              notify(game, events)
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
