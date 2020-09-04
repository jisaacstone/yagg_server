alias Yagg.Table
alias Yagg.Jobfair
alias Yagg.Board.Configuration.Alpha
alias Yagg.Table.Action

defmodule YaggTest.Jobfair do
  use ExUnit.Case

  def start() do
    {:ok, pid} = Table.new(Alpha)
    table_id = Table.pid_to_id(pid)
    :ok = Table.table_action(table_id, "p1", %Action.Join{player: "p1"})
    :ok = Table.table_action(table_id, "p2", %Action.Join{player: "p2"})
    {:ok, table} = Table.get_state(table_id)
    {table_id, table}
  end

  test "test_jf" do
    {:ok, pid} = Table.new(Alpha)
    table_id = Table.pid_to_id(pid)
    {:ok, table} = Table.get_state(table_id)
    assert %Jobfair{} = table.board
  end

  test "recruit" do
    {table_id, table} = start()
    p1 = hd(table.players)
    #units = table.board[p1.position].choices
    choices = [0,2,4]
    action = %Action.Recruit{units: choices}
    :ok = Table.table_action(table_id, p1.name, action)
    {:ok, table} = Table.get_state(table_id)
    fair = Map.get(table.board, p1.position)
    assert fair.ready == :true
  end
end
