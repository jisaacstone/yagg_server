alias Yagg.Table
alias Yagg.Event
alias Yagg.Board
alias Yagg.Jobfair
alias Yagg.Bugreport
alias Yagg.AI.Handwrit
alias Yagg.Board.Action.{Ready,Concede}
alias Yagg.Table.Action
alias Yagg.Table.Player

defmodule Yagg.AI.Server do
  use GenServer

  def start_ai(table, position, name) do
    robot = Player.new(name)
    spec = %{
      id: Yagg.AI.Server,
      start: {Yagg.AI.Server, :start_link, [[{table.id, robot, position}]]},
      restart: :transient
    }
    {:ok, _pid} = DynamicSupervisor.start_child(Yagg.AISupervisor, spec)
    {:ok, robot}
  end

  def init({table_id, robot, position}) do
    GenServer.cast(self(), :subscribe_table)
    {:ok, %{robot: robot, table_id: table_id, position: position}}
  end

  def start_link([{table_id, robot, position}]) do
    GenServer.start_link(__MODULE__, {table_id, robot, position})
  end

  def handle_cast(:subscribe_table, %{robot: robot, table_id: table_id} = state) do
    {:ok, pid} = Table.subscribe(table_id, robot.name)
    send(self(), :check_game_started)
    {:noreply, Map.put(state, :pid, pid)}
  end

  def handle_info(:check_game_started, state) do
    {:ok, table} = Table.get_state(state.pid)
    position = state.position
    _ = case table do
      %{board: %{state: :open}} ->
        Process.send_after(self(), :check_game_started, 500)
      %{board: %{state: %Board.State.Placement{ready: ^position}}} ->
        :do_nothing
      %{board: %{state: %Board.State.Placement{}}} ->
        do_initial_placement(table.board, state)
      %{board: %Jobfair{} = jf} ->
        recruit(Map.get(jf, state.position), jf.army_size, state)
      %{board: board, turn: ^position} ->
        take_your_turn(board, state)
      _ -> :do_nothing
    end
    {:noreply, state}
  end

  def handle_info(%{kind: :turn, data: %{player: pos}}, %{position: pos} = state) do
    {:ok, table} = Table.get_state(state.pid)
    take_your_turn(table.board, state)
    {:noreply, state}
  end
  def handle_info(%{kind: :gameover}, state) do
    case Table.board_action(state.pid, state.robot, %Ready{}) do
      {:err, :badstate} -> {:stop, :normal, state}  # opponent left
      :ok -> {:noreply, state}
    end
  end
  def handle_info(%{kind: :game_started}, state) do
    case Table.get_state(state.pid) do
      {:ok, %{board: %{state: %Board.State.Placement{}}} = table} ->
        do_initial_placement(table.board, state)
      {:ok, %{board: %Jobfair{} = jf}} ->
        recruit(Map.get(jf, state.position), jf.army_size, state)
    end
    {:noreply, state}
  end
  def handle_info(%{kind: :player_left}, state) do
    :ok = Table.table_action(state.pid, state.robot, %Action.Leave{})
    {:stop, :normal, state}
  end

  def handle_info(%Event{}, state) do
    # IO.inspect(unhandled_event: event)
    {:noreply, state}
  end
  def handle_info(other, state) do
    IO.inspect(%{unexpected: other})
    {:noreply, state}
  end

  def terminate(:normal, _), do: :ok
  def terminate({type, context}, state) do
    concede = %Concede{reason: "#{state.robot.name} Crashed"}
    _ = :timer.apply_after(500, Table, :board_action, [state.pid, state.robot, concede])
    Bugreport.report(
      state,
      [],
      3,
      IO.inspect("AI Proccess Terminated"),
      {type, context}
    )
    :ok
  end

  defp take_your_turn(board, state) do
    #action = Choices.move(board, state.position)
    action = Handwrit.turn(board, state.position)
    {:ok, _} = :timer.apply_after(1500, Table, :board_action, [state.pid, state.robot, action])
    :ok
  end

  defp do_initial_placement(board, %{pid: table_pid, robot: robot, position: position}) do
    actions = Handwrit.placement(board, position)

    Enum.each(
      actions,
      fn(action) -> :ok = Table.board_action(table_pid, robot, action) end
    )
    :ok = Table.board_action(table_pid, robot, %Ready{})
  end

  defp recruit(fair, army_size, %{pid: table_pid, robot: robot}) do
    indices = Map.keys(fair.choices) |> Enum.shuffle |> Enum.take(army_size)
    action = %Action.Recruit{units: indices}
    :ok = Table.table_action(table_pid, robot, action)
  end
end
