alias Yagg.Table
alias Yagg.Event
alias Yagg.Board
alias Yagg.AI.Choices
alias Yagg.Board.Action.Ready

defmodule Yagg.AI.Server do
  use GenServer

  def init({table_id, robot}) do
    GenServer.cast(self(), :subscribe_table)
    {:ok, %{robot: robot, table_id: table_id}}
  end

  def start_link([{table_id, robot}]) do
    GenServer.start_link(__MODULE__, {table_id, robot})
  end

  def handle_cast(:subscribe_table, %{robot: robot, table_id: table_id} = state) do
    {:ok, pid} = Table.subscribe(table_id, robot.name)
    send(self(), :check_game_started)
    {:noreply, Map.put(state, :pid, pid)}
  end

  def handle_info(:check_game_started, state) do
    {:ok, table} = Table.get_state(state.pid)
    case table.board do
      %Board{state: %Board.State.Placement{}} -> do_initial_placement(state, table.board)
      _ -> Process.send_after(self(), :check_game_started, 100)
    end
    {:noreply, state}
  end

  def handle_info(%Event{} = event, state) do
    IO.inspect(event)
    {:noreply, state}
  end
  def handle_info(other, state) do
    IO.inspect(%{unexpected: other})
    {:noreply, state}
  end

  defp do_initial_placement(%{pid: table_pid, robot: robot}, board) do
    %{place: place_choices} = Choices.choices(board, robot.position)
    {monarch_idx, _} = Enum.find(board.hands[robot.position], fn({_, {u, _}}) -> u.name == :monarch end)
    choices = Enum.shuffle(place_choices)
    place_monarch = Enum.find(choices, &cpm(&1, monarch_idx, board.grid))
    occupied = [{place_monarch.x, place_monarch.y} | Map.keys(board.grid)]
    choices = drop_dupes(choices, MapSet.new([monarch_idx]), MapSet.new(occupied))
    # place on average just above half the units?
    actions =  choices ++ [%Ready{}]
    IO.inspect(actions)

    Enum.each(
      actions,
      fn(action) -> :ok = Table.board_action(table_pid, robot.name, IO.inspect(action)) end
    )
    :ok
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

end
