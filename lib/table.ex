alias Yagg.{Event, Board, Jobfair}
alias Yagg.Table.Player
alias Yagg.Board.State
alias Yagg.Board.Configuration

defmodule Yagg.Table do
  use GenServer
  alias __MODULE__

  @enforce_keys [:id, :players, :board, :turn, :configuration, :history]
  @derive {Poison.Encoder, only: [:players, :board, :turn, :configuration]}
  defstruct [:subscribors | @enforce_keys]

  @type id :: String.t
  @type t() :: %Table{
    id: id,
    players: [Player.t],
    board: :nil | Board.t | Jobfair.t,
    turn: :nil | Player.position(),
    configuration: module(),
    history: any(),
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
      history: [],
    }
    DynamicSupervisor.start_child(Yagg.TableSupervisor, {Yagg.Table, [table]})
  end

  # API

  @spec get_state(pid | id) :: {:ok, t}
  def get_state(pid) when is_pid(pid) do
    GenServer.call(pid, :get_state)
  end
  def get_state(table_id) do
    {:ok, pid} = get(table_id)
    GenServer.call(pid, :get_state)
  end

  @spec get_player_state(id, String.t) :: {:ok, %{grid: list, hand: list}} | {:err, atom}
  def get_player_state(table_id, player_name) do
    {:ok, pid} = get(table_id)
    case GenServer.call(pid, :get_state) do
      {:err, _} = err -> err
      {:ok, table} ->
        case Player.by_name(table, player_name) do
          %Player{position: position} -> 
            table.board.__struct__.units(table.board, position)
          _ -> {:err, :unknown_player}
        end
    end
  end

  @spec subscribe(id, String.t) :: {:ok, pid}
  def subscribe(table_id, player) do
    {:ok, pid} = get(table_id)
    IO.inspect(table: table_id, pid: pid)
    Process.monitor(pid)
    GenServer.call(pid, {:subscribe, player})
    {:ok, pid}
  end

  @spec table_action(id | pid, String.t, struct) :: :ok | {:err, atom}
  def table_action(pid, player_name, action) when is_pid(pid) do
    GenServer.call(pid, {:table_action, player_name, action})
  end
  def table_action(table_id, player_name, action) do
    {:ok, pid} = get(table_id)
    table_action(pid, player_name, action)
  end

  @spec board_action(id | pid, String.t, struct) :: :ok | {:err, atom}
  def board_action(pid, player_name, action) when is_pid(pid) do
    GenServer.call(pid, {:board_action, player_name, action})
  end
  def board_action(table_id, player_name, action) do
    {:ok, pid} = get(table_id)
    board_action(pid, player_name, action)
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

  def handle_call(:get_state, _from, table) do
    {:reply, {:ok, table}, table}
  end
  def handle_call({:subscribe, player}, {pid, _tag}, %{subscribors: subs} = table) do
    {:reply, :ok, %{table | subscribors: [{player, pid} | subs]}}
  end

  def handle_call({:table_action, player_name, action}, _from, table) do
    player = Player.by_name(table, player_name)
    # try do
      case Yagg.Table.Action.resolve(action, table, player) do
        {:err, _} = err -> {:reply, err, table}
        {table, events} ->
          notify(table, events)
          {:reply, :ok, table}
      end
    # rescue
    #   FunctionClauseError -> {:reply, {:err, :invalid_or_unknown}, table}
    # end
  end

  def handle_call({:board_action, player_name, action}, _from, table) do
    player = Player.by_name(table, player_name)
    # try do
      cond do
        player == :notfound -> {:reply, {:err, :player_invalid}, table}
        table.board && Map.get(table.board, :state) == :battle and table.turn != player.position ->
          {:reply, {:err, :notyourturn}, table}
        :true ->
          case Board.Action.resolve(action, table.board, player.position) do
            {:err, _} = err -> {:reply, err, table}
            {board, events} ->
              # One action per turn. Successful move == next turn
              table = %{table | board: board, history: [{table.board, action} | table.history]}
              {table, events} = if (Map.get(board, :state) == :battle) do
                table = nxtrn(table)
                {table, [Event.Turn.new(player: table.turn) | events]}
              else
                {table, events}
              end
              notify(table, events)
              {:reply, :ok, table}
          end
      end
    # rescue
      # FunctionClauseError -> {:reply, {:err, :invalid_or_unknown}, table}
    # end
  end

  def handle_call(msg, _from, state) do
    {:reply, {:err, {:unknown_msg, msg}}, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, reason}, %Table{players: players} = table) do
    case Enum.find(players, fn p -> elem(p, 1) == pid end) do
      :nil -> {:noreply, table}
      {name, _} -> 
        :ok = notify(table, Event.new(:player_disconnect, %{player: name, reason: reason}))
        subs =  Enum.reject(table.subscribors, fn({_, ^pid}) -> :true; (_) -> :false end)
        {:noreply, %{table | subscribors: subs}}
    end
  end
  def handle_info(other, table) do
    IO.inspect([unexpected_info: other])
    {:noreply, table}
  end

  # Private

  defp notify(_game, []) do
    :ok
  end
  defp notify(table, [event | events]) do
    notify(table, event)
    notify(table, events)
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

  defp nxtrn(%Table{board: %Board{state: %State.Placement{}}} = table), do: table
  defp nxtrn(%Table{turn: :north} = table), do: %{table | turn: :south}
  defp nxtrn(%Table{turn: :south} = table), do: %{table | turn: :north}
  defp nxtrn(%Table{turn: :nil} = table), do: %{table | turn: :north}
end
