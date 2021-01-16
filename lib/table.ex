alias Yagg.{Event, Board, Jobfair, Bugreport}
alias Yagg.Table.Player
alias Yagg.Board.State
alias Yagg.Board.Grid
alias Yagg.Board.Configuration

defmodule Yagg.Table do
  use GenServer
  alias __MODULE__

  @enforce_keys [:id, :players, :board, :turn, :configuration, :history]
  @derive {Poison.Encoder, only: [:players, :board, :turn, :configuration]}
  defstruct [:subscribors, :timer | @enforce_keys]

  @opaque history :: [Board.t]

  @type id :: String.t
  @type t :: %Table{
    id: id,
    players: [{Player.position, Player.t}],
    board: :nil | Board.t | Jobfair.t,
    turn: :nil | Player.position,
    configuration: Configuration.t,
    history: history,
    timer: :nil | reference
  }

  def start_link(table, args \\ []) do
    GenServer.start_link(__MODULE__, table, args)
  end

  def get(table_id) do
    case Registry.lookup(Registry.TableNames, table_id) do
      [] -> {:err, :id_not_found}
      [{pid, :nil}] -> {:ok, pid}
    end
  end

  @spec list() :: [id]
  def list() do
    # get all keys (copied from the documentation)
    Registry.select(Registry.TableNames, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  @spec new(module) :: {:ok, t}
  def new(configuration \\ Board.Configuration.Random) do
    config = configuration.new()
    id = "#{:erlang.unique_integer([:positive])}"
    table = %Table{
      id: id,
      players: [],
      subscribors: [],
      board: :nil,
      turn: :nil,
      configuration: config,
      history: [],
      timer: nil,
    }
    {:ok, pid} = DynamicSupervisor.start_child(
      Yagg.TableSupervisor,
      %{
        id: Yagg.Table,
        start: {
          Yagg.Table,
          :start_link,
          [table, [name: {:via, Registry, {Registry.TableNames, id}}]]
        }, 
        restart: :transient
      }
    )
    IO.inspect(table: pid, config: configuration)
    {:ok, table}
  end

  @spec gameover(t, Board.t, Player.position, String.t, [Event.t]) :: {t, [Event.t]}
  def gameover(table, board, winner, reason, events \\ []) do
    board = %{board | state: %State.Gameover{winner: winner, reason: reason}}
    gameover_event = Event.Gameover.new(winner: winner, reason: reason)
    {%{table | board: board, turn: :nil}, [gameover_event | events]}
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

  @spec get_player_state(id, non_neg_integer) :: {:ok, %{grid: list, hand: list}} | {:err, atom}
  def get_player_state(table_id, id) do
    {:ok, pid} = get(table_id)
    case GenServer.call(pid, :get_state) do
      {:err, _} = err -> err
      {:ok, table} ->
        case Player.by_id(table, id) do
          {position, %Player{}} -> 
            table.board.__struct__.units(table.board, position)
          _ -> {:err, :unknown_player}
        end
    end
  end

  @spec subscribe(id, String.t) :: {:ok, pid}
  def subscribe(table_id, player) do
    {:ok, pid} = get(table_id)
    Process.monitor(pid)
    GenServer.call(pid, {:subscribe, player})
    {:ok, pid}
  end

  @spec table_action(id | pid, non_neg_integer | Player.t, struct) :: :ok | {:err, atom}
  def table_action(pid, player, action) when is_pid(pid) do
    GenServer.call(pid, {:table_action, player, action})
  end
  def table_action(pid, player_id, action) when is_integer(player_id) do
    case Player.fetch(player_id) do
      {:ok, player} -> table_action(pid, player, action)
      {:err, _} = err -> err
    end
  end
  def table_action(table_id, player, action) do
    {:ok, pid} = get(table_id)
    table_action(pid, player, action)
  end

  @spec board_action(id | pid, non_neg_integer | Player.t, struct) :: :ok | {:err, atom}
  def board_action(pid, player, action) when is_pid(pid) do
    GenServer.call(pid, {:board_action, player, action})
  end
  def board_action(pid, player_id, action) when is_integer(player_id) do
    case Player.fetch(player_id) do
      {:ok, player} -> board_action(pid, player, action)
      {:err, _} = err -> err
    end
  end
  def board_action(table_id, player, action) do
    {:ok, pid} = get(table_id)
    board_action(pid, player, action)
  end

  # Callbacks

  def init(%Table{} = table) do
    {:ok, table}
  end

  def handle_call(:get_state, _from, table) do
    {:reply, {:ok, table}, table}
  end
  def handle_call({:subscribe, player}, {pid, _tag}, %{subscribors: subs} = table) do
    {:reply, :ok, %{table | subscribors: [{player, pid} | subs]}}
  end

  def handle_call({:table_action, player, action}, _from, table) do
    case handle_table_action(player, action, table) do
      {:err, _} = err -> {:reply, err, table}
      {:ok, table} -> {:reply, :ok, table}
      :shutdown_table -> {:stop, :normal, :ok, table}
    end
  end

  def handle_call({:board_action, player, action}, _, table) do
    case handle_board_action(player, action, table) do
      {:err, _} = err -> {:reply, err, table}
      {:ok, table} -> {:reply, :ok, table}
    end
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
  def handle_info(:timeout, table) do
    IO.inspect("TIMEOUT")
    {table, events} = Table.Timer.timeout(table)
    notify(table, events)
    {:noreply, table}
  end
  def handle_info(other, table) do
    IO.inspect([unexpected_info: other])
    {:noreply, table}
  end

  def terminate({:shutdown, reason}, table) do
    Bugreport.report(
      table.board,
      table.history,
      3,
      "Proccess Terminated",
      reason
    )
  end
  def terminate({err, reason}, table) do
    Bugreport.report(
      table.board,
      table.history,
      3,
      "Proccess Terminated",
      {err, reason}
    )
  end
  def terminate(_, _), do: :ok

  # Private

  defp handle_table_action(player, action, table) do
    case Yagg.Table.Action.resolve(action, table, player) do
      {:err, _} = err -> err
      :shutdown_table -> :shutdown_table
      {newtable, events} ->
        {table, events} = handle_timer(table.board, newtable, events)
        notify(table, events)
        {:ok, table}
    end
  end

  defp handle_board_action(%{id: id}, action, table) do
    case Player.by_id(table, id) do
      :notfound -> {:err, :playernotfound}
      {position, _} -> handle_board_action_2(position, action, table)
    end
  end
  defp handle_board_action_2(position, action, table) do
    if table.board && Map.get(table.board, :state) == :battle and table.turn != position do
      {:err, :notyourturn}
    else
      case Board.Action.resolve(action, table.board, position) do
        {:err, _} = err -> err
        {board, events} ->
          {table, events} = handle_gameover(table, Map.get(board, :state), events)
          {board, events} = check_all_immobile(board, events)
          newtable = add_history(table, board, action)
          {table, events} = handle_timer(table.board, newtable, events)
          {table, events} = handle_turn(table, events)
          notify(table, events)
          {:ok, table}
      end
    end
  end

  defp handle_gameover(%{board: %{state: %State.Gameover{}}} = table, %State.Gameover{}, events) do
    {table, events}
  end
  defp handle_gameover(table, %{winner: winner, reason: reason}, events) do
    {
      %{table | turn: :nil},
      events ++ [Event.Gameover.new(winner: winner, reason: reason)]
    }
  end
  defp handle_gameover(table, _, events) do
    {table,events}
  end

  defp handle_timer(:nil, %{board: %{}} = table, events) do
    Table.Timer.start_timed_phase(table, events)
  end
  defp handle_timer(%{state: %State.Gameover{}}, %{board: %Jobfair{}} = table, events) do
    Table.Timer.start_timed_phase(table, events)
  end
  defp handle_timer(%{state: %State.Gameover{}}, %{board: %{state: %State.Placement{}}} = table, events) do
    Table.Timer.start_timed_phase(table, events)
  end
  defp handle_timer(%Jobfair{}, %{board: %{state: %State.Placement{}}} = table, events) do
    Table.Timer.start_timed_phase(table, events)
  end
  defp handle_timer(%{state: :battle}, %{board: %{state: %State.Gameover{}}} = table, events) do
    _ = if table.timer do
      Process.cancel_timer(table.timer)
    end
    {table, events}
  end
  defp handle_timer(_, table, events) do
    {table, events}
  end

  defp check_all_immobile(%{state: :battle, hands: %{north: n, south: s}} = board, events) when map_size(n) > 0 and map_size(s) > 0, do: {board, events}
  defp check_all_immobile(%{state: :battle, hands: hands, grid: grid} = board, events) do
    values = Map.values(grid)
    north = map_size(hands.north) == 0 and no_mobile_units(:north, values)
    south = map_size(hands.south) == 0 and no_mobile_units(:south, values)
    case {north, south} do
      {:false, :false} -> {board, events}
      {:true, :true} ->
        {grid, events} = Grid.reveal_units(grid)
        {%{board | grid: grid, state: %State.Gameover{winner: :draw}}, [Event.Gameover.new(winner: :draw) | events]}
      {:true, :false} ->
        {grid, events} = Grid.reveal_units(grid)
        {
          %{board | grid: grid, state: %State.Gameover{winner: :south, reason: "cannot move"}},
          [Event.Gameover.new(winner: :south, reason: "cannot move") | events]
        }
      {:false, :true} ->
        {grid, events} = Grid.reveal_units(grid)
        {
          %{board | grid: grid, state: %State.Gameover{winner: :north, reason: "cannot move"}},
          [Event.Gameover.new(winner: :north, reason: "cannot move") | events]
        }
    end
  end
  defp check_all_immobile(board, events), do: {board, events}

  defp no_mobile_units(_, []), do: :true
  defp no_mobile_units(p, [%{position: p, attack: a} | _]) when is_integer(a), do: :false
  defp no_mobile_units(p, [_ | t]), do: no_mobile_units(p, t)

  defp add_history(table, board, action) do
      %{table | board: board, history: [{table.board, action} | table.history]}
  end

  defp handle_turn(%{board: %{state: :battle}} = table, events) do
    table = nxtrn(table)
    events = [Event.Turn.new(player: table.turn) | events]
    Table.Timer.turn_timer(table, table.turn, events)
  end
  defp handle_turn(table, events), do: {table, events}

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
            if Enum.any?(players, fn({pos, p}) -> p.id == player and pos == stream end) do
              send(pid, event)
            end
        end
      end
    )
  end

  defp nxtrn(%Table{turn: :north} = table), do: %{table | turn: :south}
  defp nxtrn(%Table{turn: :south} = table), do: %{table | turn: :north}
  defp nxtrn(%Table{turn: :nil} = table), do: %{table | turn: Enum.random([:north, :south])}
end
