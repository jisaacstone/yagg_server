alias YaggServer.Endpoint
alias YaggServer.Game

defmodule YaggServerTest.Endpoint do
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

  def recieve_event() do
    receive do
      %{"event" => _event_type} = event ->
        event
      other ->
        IO.inspect([unexpected: other])
        recieve_event()
      after
        0 -> raise "no_message"
    end
  end

  test "game join" do
    %{status: status, resp_body: body} = send_json("/game", %{"action" => "create"})
    assert status == 200
    assert %{"id" => gid} = Poison.decode!(body)
    {:ok, pid} = Game.get(gid)
    :ok = GenServer.call(pid, {:join, "testplayer"})
    {sse_pid, _ref} = spawn_monitor(fn -> conn(:get, "/game_events/#{gid}") end)
    assert Process.alive?(sse_pid)
    %{"event" => event_type} = recieve_event()
    assert event_type == "player_joined"
    Process.exit(sse_pid, :kill)
    %{"event" => event_type} = recieve_event()
    assert event_type == "player_disconnect"
    Process.exit(pid, :kill)
  end
end
