alias Yagg.Table
alias Yagg.Event
alias Yagg.Board
alias Yagg.Board.{State, Grid}
alias Yagg.Jobfair

defmodule Table.Timer do
  @moduledoc "Timed events - initial setup, taking turns"

  def set(table, milliseconds) do
    _ = if table.timer do
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

  def kill_table_timer(table) do
    milliseconds = 20 * 1000
    table = set(table, milliseconds)
    table
  end
    

  def timeout(table) do
    # check for race conditions
    case Process.read_timer(table.timer) do
      :false -> end_game(table) |> check_players()
      _ -> {table, []}
    end
  end

  defp end_game(%{board: %{state: :battle}, turn: position} = table) do
    {grid, events} = Grid.reveal_units(table.board.grid)
    winner = Table.Player.opposite(position)
    Table.gameover(table, %{table.board | grid: grid}, winner, "time's up", events)
  end

  defp end_game(%{board: %Board{state: %State.Placement{ready: ready}}} = table) do
    {grid, events} = Grid.reveal_units(table.board.grid)
    winner = whoisready(ready)
    board = %{table.board | grid: grid}
    Table.gameover(table, board, winner, "time's up", events)
  end

  defp end_game(%{board: %Jobfair{}} = table) do
    board = Board.new(table.configuration)
    Table.gameover(table, board, whoisready(table.board), "time's up")
  end

  defp end_game(table) do
    {table, []}
  end

  defp check_players({%{players: [_, _]} = table, events}) do
    {table, events}
  end
  defp check_players({_table, events}) do
    {:shutdown_table, [Event.TableShutdown.new() | events]}
  end

  defp whoisready(%{north: %{ready: :true}}), do: :north
  defp whoisready(%{south: %{ready: :true}}), do: :south
  defp whoisready(%{}), do: :draw
  defp whoisready(:nil), do: :draw
  defp whoisready(position), do: position
end
