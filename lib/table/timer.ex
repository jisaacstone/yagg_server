alias Yagg.Table
alias Yagg.Event
alias Yagg.Board
alias Yagg.Board.{State, Grid}

defmodule Table.Timer do
  def set(table, milliseconds) do
    _ = if (table.timer) do
      Process.cancel_timer(table.timer)
    end
    timer = Process.send_after(self(), :timeout, milliseconds)
    %{table | timer: timer}
  end

  def start_timed_phase(table, events \\ []) do
    milliseconds = 6 * 60 * 1000
    table = set(table, milliseconds)
    {table, [Event.Timer.new(player: :all, timer: milliseconds) | events]}
  end

  def turn_timer(table, position, events \\ []) do
    milliseconds = 2 * 60 * 1000
    table = set(table, milliseconds)
    {table, [Event.Timer.new(player: position, timer: milliseconds) | events]}
  end

  def timeout(table) do
    # check for race conditions
    case Process.read_timer(table.timer) do
      :false -> end_game(table)
      _ -> {table, []}
    end
  end

  defp end_game(%{board: %{state: :battle}, turn: position} = table) do
    {grid, events} = Grid.reveal_units(table.board.grid)
    winner = Table.Player.opposite(position)
    board = %{table.board | state: %State.Gameover{winner: winner}, grid: grid}
    {%{table | board: board}, [Event.Gameover.new(winner: winner) | events]}
  end

  defp end_game(%{board: %Board{state: %State.Placement{ready: ready}}} = table) do
    {grid, events} = Grid.reveal_units(table.board.grid)
    winner = case ready do
      :nil -> :draw
      position -> position
    end
    board = %{table.board | state: %State.Gameover{winner: winner}, grid: grid}
    {%{table | board: board}, [Event.Gameover.new(winner: winner) | events]}
  end
  defp end_game(table) do
    # TODO: handle jobfair timeout
    {table, []}
  end
end
