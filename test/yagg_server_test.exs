alias Yagg.{Endpoint, Event, Table}
alias Yagg.Table.Action.Join

defmodule YaggTest.Endpoint do
  use ExUnit.Case
  use Plug.Test

  @opts Endpoint.init([])

  # API driven tests?
  # A framework for these would be useful to find...
  
  def send_json(url, body) do
    conn(:post, url, body)
      |> put_req_header("content-type", "application/json")
      |> Endpoint.call(@opts)
  end

  # GET request
  def get_200(url) do
    %{status: status, resp_body: body} = Endpoint.call(conn(:get, url), @opts)
    assert status == 200
    Poison.Parser.parse!(body, %{keys: :atoms})
  end

  def call_200(url, body) do
    %{status: status, resp_body: body} = send_json(url, Poison.encode!(body))
    assert status == 200
    Poison.Parser.parse!(body, %{keys: :atoms!})
  end

  def call_204(url, body) do
    %{status: status} = send_json(url, Poison.encode!(body))
    assert status == 204
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
    %{status: status, resp_body: body} = send_json("/table/new", "{}")
    assert status == 200
    assert %{"id" => gid} = Poison.decode!(body)
    {:ok, _pid} = Table.subscribe(gid, "player1")
    :ok = Table.table_action(gid, "player1", %Join{player: "player1"})
    %{kind: event_type} = recieve_event()
    assert event_type == :player_joined
  end

  test "game configurations" do
    %{status: 200, resp_body: body} = conn(:get, "/configurations") |> Endpoint.call(@opts)
    assert %{"random" => _} = Poison.decode!(body)
  end

  test "start game" do
    %{id: table_id} = call_200("/table/new", %{})
    call_204("/table/#{table_id}/a/join", %{player: "p1"})
    call_204("/table/#{table_id}/a/join", %{player: "p2"})
    table = get_200("/table/#{table_id}/state")
    south = Enum.find(table.players, fn(p) -> p.position == "south" end)
    call_204("/board/#{table_id}/a/place?player=#{south.name}", %{index: 1, x: 0, y: 0})
  end

  test "new with config" do
    %{id: table_id} = call_200("/table/new", %{"configuration" => "bigga"})
    call_204("/table/#{table_id}/a/join", %{player: "p1"})
    table = get_200("/table/#{table_id}/state")
    assert table.configuration.initial_module == "Elixir.Yagg.Board"
    call_204("/table/#{table_id}/a/join", %{player: "p2"})
    table = get_200("/table/#{table_id}/state")
    assert table.board.grid[:"2,2"] == "block"
  end

  test "with ai" do
    %{id: table_id} = call_200("/table/new", %{"configuration" => "bigga"})
    call_204("/table/#{table_id}/a/join", %{player: "p1"})
    table = get_200("/table/#{table_id}/state")
    assert [%{name: "p1"}] = table.players
    call_204("/table/#{table_id}/a/ai", %{name: "random"})
    table = get_200("/table/#{table_id}/state")
    assert [_, _] = table.players
    stop_ai_servers()
  end

  test "bad action" do
    %{id: table_id} = call_200("/table/new", %{})
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
