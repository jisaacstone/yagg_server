alias Yagg.Table
alias Yagg.Board
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

  test "recruit" do
    {table_id, table} = start()
    p1 = hd(table.players)
    choices = [0,2,4]
    action = %Action.Recruit{units: choices}
    :ok = Table.table_action(table_id, p1.name, action)
    {:ok, table} = Table.get_state(table_id)
    fair = Map.get(table.board, p1.position)
    assert fair.ready == :true
  end

  test "gamestart" do
    {table_id, table} = start()
    [p1, p2] = table.players
    u1 = Map.get(table.board, p1.position).choices
    u2 = Map.get(table.board, p2.position).choices
    {c1, c2} = {[0,2,4], [1,3,4]}
    :ok = Table.table_action(table_id, p1.name, %Action.Recruit{units: c1})
    :ok = Table.table_action(table_id, p2.name, %Action.Recruit{units: c2})
    {:ok, table} = Table.get_state(table_id)
    assert %Board{} = table.board
    h1 = table.board.hands[p1.position]
    hu1 = Enum.map(h1, fn({_, {v, _}}) -> v end) |> MapSet.new()
    ou1 = [u1[0], u1[2], u1[4]] |> MapSet.new()
    assert hu1 == ou1
    h2 = table.board.hands[p2.position]
    hu2 = Enum.map(h2, fn({_, {v, _}}) -> v end) |> MapSet.new()
    ou2 = [u2[1], u2[3], u2[4]] |> MapSet.new()
    assert hu2 == ou2
  end
end
