alias Yagg.{Endpoint, Event, Table}
alias Yagg.Table.Player
alias Yagg.Table.Action.Join
alias Yagg.Board
import Helper.Board

defmodule YaggTest.Endpoint do
  use ExUnit.Case
  use Plug.Test

  @opts Endpoint.init([])

  # API driven tests?
  # A framework for these would be useful to find...
  
  def send_json(url, body), do: send_json(url, body, :nil)
  def send_json(url, body, :nil) do
    conn(:post, url, body)
      |> put_req_header("content-type", "application/json")
      |> Endpoint.call(@opts)
  end
  def send_json(url, body, player_id) do
    conn(:post, url, body)
      |> put_req_header("content-type", "application/json")
      |> put_req_header("x-userid", "#{player_id}")
      |> Endpoint.call(@opts)
  end

  # GET request
  def get_200(url) do
    %{status: status, resp_body: body} = Endpoint.call(conn(:get, url), @opts)
    assert status == 200
    Poison.Parser.parse!(body, %{keys: :atoms})
  end

  def call_200(url, body, player_id \\ :nil) do
    %{status: status, resp_body: body} = send_json(url, Poison.encode!(body), player_id)
    assert status == 200
    Poison.Parser.parse!(body, %{keys: :atoms!})
  end

  def call_204(url, body, player_id \\ :nil) do
    assert %{status: 204} = send_json(url, Poison.encode!(body), player_id)
    :ok
  end

  def recieve_event() do
    receive do
      %Event{} = event ->
        event
      other ->
        IO.inspect([unexpected: other])
        recieve_event()
      after
        10 -> raise "no_message"
    end
  end

  test "game join" do
    %{id: id, name: "bob"} = call_200("/player/guest", %{"name" => "bob"})
    %{status: status, resp_body: body} = send_json("/table/new", "{}", id)
    assert status == 200
    assert %{"id" => gid} = Poison.decode!(body)
    {:ok, _pid} = Table.subscribe(gid, "player1")
    :ok = Table.table_action(gid, Player.new("player1"), %Join{})
    %{kind: event_type} = recieve_event()
    assert event_type == :player_joined
  end

  test "timer" do
    %{id: bob_id, name: "bob"} = call_200("/player/guest", %{"name" => "bob"})
    %{status: status, resp_body: body} = send_json("/table/new", ~s({"configuration": "fivers"}), bob_id)
    assert status == 200
    assert %{"id" => gid} = Poison.decode!(body)
    :ok = Table.table_action(gid, Player.new("player1"), %Join{})
    {:ok, _pid} = Table.subscribe(gid, "bob")
    :ok = Table.table_action(gid, bob_id, %Join{})
    assert %{kind: :timer} = recieve_event()
    assert %{kind: :player_joined} = recieve_event()
    assert %{kind: :game_started} = recieve_event()
  end

  test "ready timeout" do
    player1 = Table.Player.new("north")
    player2 = Table.Player.new("south")
    board = new_board() |> Map.put(:state, %Board.State.Placement{ready: :north})
    tid = "test_table"
    table = %Table{
      id: tid, turn: :nil, board: board,
      history: [], players: [north: player1, south: player2],
      timer: Process.send_after(self(), :timeout, 0),
      configuration: %{}, subscribors: []}
    {:ok, pid} = Table.start_link(table, [name: {:via, Registry, {Registry.TableNames, tid}}])

    {:ok, pid} = Table.subscribe(tid, "south")
    Process.sleep(1)
    send(pid, :timeout)
    assert %{kind: :gameover, data: %{winner: :north}} = recieve_event()
  end

  test "game configurations" do
    %{status: 200, resp_body: body} = conn(:get, "/configurations") |> Endpoint.call(@opts)
    configurations = Poison.decode!(body)
    assert %{"name" => "random"} = Enum.find(configurations, fn(c) -> c["module"] == "Elixir.Yagg.Board.Configuration.Random" end)
  end

  test "start game" do
    %{id: id, name: "bob"} = call_200("/player/guest", %{"name" => "bob"})
    %{id: p2id} = call_200("/player/guest", %{"name" => "jame"})
    %{id: table_id} = call_200("/table/new", %{"configuration" => "strat"}, id)
    call_204("/table/#{table_id}/a/join", %{}, id)
    call_204("/table/#{table_id}/a/join", %{}, p2id)
    table = get_200("/table/#{table_id}/state")
    south = Enum.find(table.players, fn(p) -> p.position == "south" end)
    call_204("/board/#{table_id}/a/place?player=#{south.player.name}", %{index: 1, x: 1, y: 1}, south.player.id)
  end

  test "new with config" do
    %{id: id, name: "bob"} = call_200("/player/guest", %{"name" => "bob"})
    %{id: table_id} = call_200("/table/new", %{"configuration" => "iceslide"}, id)
    call_204("/table/#{table_id}/a/join", %{}, id)
    table = get_200("/table/#{table_id}/state")
    assert table.configuration.initial_module == "Elixir.Yagg.Jobfair"
    %{id: p2id} = call_200("/player/guest", %{"name" => "djill"})
    call_204("/table/#{table_id}/a/join", %{}, p2id)
    table = get_200("/table/#{table_id}/state")
    assert [_, _] = table.players
  end

  test "with ai" do
    %{id: id, name: "bob"} = call_200("/player/guest", %{"name" => "bob"})
    %{id: table_id} = call_200("/table/new", %{"configuration" => "iceslide"}, id)
    call_204("/table/#{table_id}/a/join", %{player: "p1"}, id)
    table = get_200("/table/#{table_id}/state")
    assert [%{player: %{name: "bob"}}] = table.players
    call_204("/table/#{table_id}/a/ai", %{name: "random"}, id)
    table = get_200("/table/#{table_id}/state")
    assert [_, _] = table.players
    stop_ai_servers()
  end

  test "bad action" do
    %{id: id, name: "bob"} = call_200("/player/guest", %{"name" => "bob"})
    %{id: table_id} = call_200("/table/new", %{}, id)
    assert %{status: 400} = send_json(
      "/table/#{table_id}/a/oops",
      Poison.encode!(%{player: "p1"})
    )
  end

  defp stop_ai_servers() do
    Enum.map(
      Supervisor.which_children(Yagg.AISupervisor),
      fn ({id, _, _, _}) -> Supervisor.terminate_child(Yagg.AISupervisor, id) end
    )
  end
end
