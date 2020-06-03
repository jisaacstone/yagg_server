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

  def call_200(url, body) do
    %{status: status, resp_body: body} = send_json(url, Poison.encode!(body))
    assert status == 200
    Poison.Parser.parse!(body, %{keys: :atoms!})
  end

  def call_204(url, body) do
    %{status: status, resp_body: body} = send_json(url, Poison.encode!(body))
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
    assert %{"alpha" => _} = Poison.decode!(body)
  end

  test "start game" do
    %{id: table_id} = call_200("/table/new", %{})
    call_204("/table/#{table_id}/a/join", %{player: "p1"})
    call_204("/table/#{table_id}/a/join", %{player: "p2"})
    call_204("/board/#{table_id}/a/place?player=p1", %{index: 1, x: 4, y: 4})
  end

end
