alias Yagg.Table
alias Yagg.Event
alias Yagg.Board
alias Yagg.Jobfair
alias Yagg.Bugreport
alias Yagg.AI.Choices
alias Yagg.Board.Action.Ready
alias Yagg.Table.Action

defmodule Yagg.AI.Server do
  use GenServer

  def init({table_id, robot}) do
    IO.inspect(aiinit: robot)
    GenServer.cast(self(), :subscribe_table)
    {:ok, %{robot: robot, table_id: table_id}}
  end

  def start_link([{table_id, robot}]) do
    GenServer.start_link(__MODULE__, {table_id, robot})
  end

  def handle_cast(:subscribe_table, %{robot: robot, table_id: table_id} = state) do
    {:ok, pid} = Table.subscribe(table_id, robot.name)
    send(self(), :check_game_started)
    IO.inspect(:cgs_called)
    {:noreply, Map.put(state, :pid, pid)}
  end

  def handle_info(:check_game_started, state) do
    {:ok, table} = Table.get_state(state.pid)
    position = state.robot.position
    _ = case table do
      %{board: %{state: :open}} ->
        Process.send_after(self(), :check_game_started, 500)
      %{board: %{state: %Board.State.Placement{ready: ^position}}} ->
        :do_nothing
      %{board: %{state: %Board.State.Placement{}}} ->
        do_initial_placement(table.board, state)
      %{board: %Jobfair{} = jf} ->
        recruit(Map.get(jf, state.robot.position), jf.army_size, state)
      %{board: board, turn: ^position} ->
        take_your_turn(board, state)
      _ -> :do_nothing
    end
    IO.inspect(:cgs_done)
    {:noreply, state}
  end

  def handle_info(%{kind: :turn, data: %{player: pos}}, %{robot: %{position: pos}} = state) do
    {:ok, table} = Table.get_state(state.pid)
    take_your_turn(table.board, state)
    {:noreply, state}
  end
  def handle_info(%{kind: :gameover}, state) do
    :ok = Table.board_action(state.pid, state.robot.name, IO.inspect(%Ready{}))
    {:noreply, state}
  end
  def handle_info(%{kind: :game_started}, state) do
    case Table.get_state(state.pid) do
      {:ok, %{board: %{state: %Board.State.Placement{}}} = table} ->
        do_initial_placement(table.board, state)
      {:ok, %{board: %Jobfair{} = jf}} ->
        recruit(Map.get(jf, state.robot.position), jf.army_size, state)
    end
    {:noreply, state}
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
    Bugreport.report(
      state,
      [],
      3,
      "AI Proccess Terminated",
      {type, context}
    )
    :ok
  end

  defp take_your_turn(board, state) do
    action = Choices.move(board, state.robot.position)
    {:ok, _} = :timer.apply_after(500, Table, :board_action, [state.pid, state.robot.name, action])
    :ok
  end

  defp do_initial_placement(board, %{pid: table_pid, robot: robot}) do
    %{place: place_choices} = Choices.choices(board, robot.position)
    {monarch_idx, _} = Enum.find(board.hands[robot.position], fn({_, {u, _}}) -> u.name == :monarch end)
    choices = Enum.shuffle(place_choices)
    # place monarch first to ensure there will be space
    place_monarch = Enum.find(choices, &cpm(&1, monarch_idx, board.grid))
    occupied = [{place_monarch.x, place_monarch.y} | Map.keys(board.grid)]
    choices = drop_dupes(choices, MapSet.new([monarch_idx]), MapSet.new(occupied))
    # place on average just above half the units?
    actions =  [place_monarch | choices]

    Enum.each(
      actions,
      fn(action) -> :ok = Table.board_action(table_pid, robot.name, IO.inspect(action)) end
    )
    :ok = Table.board_action(table_pid, robot.name, IO.inspect(%Ready{}))
  end

  defp cpm(%{index: i, x: x, y: y}, i, grid) do
    case grid[{x, y}] do
      :nil -> :true
      _ -> :false
    end
  end
  defp cpm(_, _, _), do: :false

  defp drop_dupes([], _, _), do: []
  defp drop_dupes([choice | choices], ids, coords) do
    case {Enum.member?(ids, choice.index), Enum.member?(coords, {choice.x, choice.y})} do
      {:false, :false} ->
        [choice | drop_dupes(choices, MapSet.put(ids, choice.index), MapSet.put(coords, {choice.x, choice.y}))]
      _ -> drop_dupes(choices, ids, coords)
    end
  end

  defp recruit(fair, army_size, %{pid: table_pid, robot: robot}) do
    indices = Map.keys(fair.choices) |> Enum.shuffle |> Enum.take(army_size)
    action = %Action.Recruit{units: indices}
    :ok = Table.table_action(table_pid, robot.name, action)
  end
end
