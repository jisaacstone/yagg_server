alias Yagg.{Endpoint, Game, Event, Action.Join}

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
    %{status: status, resp_body: body} = send_json("/game/create", %{})
    assert status == 200
    assert %{"id" => gid} = Poison.decode!(body)
    {:ok, _pid} = Game.subscribe(gid, "player1")
    :ok = Game.act(gid, "player1", %Join{player: "player1"})
    %{kind: event_type} = recieve_event()
    assert event_type == :player_joined
  end
end
