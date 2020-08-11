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

  defmodule Subscribor do
    use GenServer
    def init([table_id, player_name]) do
      {:ok, _} = Table.subscribe(table_id, player_name)
      {:ok, :queue.new()}
    end

    def handle_info(%Event{} = event, queue) do
      {:noreply, :queue.in(IO.inspect(event), queue)}
    end
    def handle_info({:fe, _, from, 5}, queue) do
      GenServer.reply(from, :not_found)
      {:noreply, queue}
    end
    def handle_info({:fe, kind, from, tries}, queue) do
      IO.inspect(try: tries)
      queue = find_event(kind, queue, from, tries)
      {:noreply, queue}
    end
    def handle_info(other, queue) do
      IO.inspect([unexpected: other])
      {:noreply, queue}
    end

    def handle_call(:recieve_event, _from, queue) do
      case :queue.out(queue) do
        {{:value, event}, queue} ->
          {:reply, event, queue}
        {:empty, queue} ->
          {:reply, :empty, queue}
      end
    end

    def handle_call({:find_event, type}, from, queue) do
      queue = find_event(type, queue, from)
      {:noreply, queue}
    end

    def find_event(kind, queue, from, tries \\ 0) do
      case :queue.out(queue) do
        {:value, %{kind: ^kind} = event, queue} ->
          GenServer.reply(from, event)
          queue
        {{:value, %{}}, queue} ->
          find_event(kind, queue, from)
        {:empty, queue} ->
          Process.send_after(self(), {:fe, kind, from, tries + 1}, 100)
          queue
      end
    end
  end


  def recieve_event(timeout \\ 10) do
    receive do
      %Event{} = event ->
        event
      after
        timeout -> :no_message
    end
  end

  def find_event(kind, timeout \\ 10) do
    case IO.inspect(recieve_event()) do
      %{kind: ^kind} = event -> event
      :no_message -> :no_message
      _ -> find_event(kind, timeout)
    end
  end

  test "game join" do
    %{status: status, resp_body: body} = send_json("/table/new", "{}")
    assert status == 200
    assert %{"id" => gid} = Poison.decode!(body)
    {:ok, subr} = GenServer.start_link(Subscribor, [gid, "player1"])
    :ok = Table.table_action(gid, "player1", %Join{player: "player1"})
    %{kind: event_type} = GenServer.call(subr, :recieve_event)
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
    table = get_200("/table/#{table_id}/state")
    south = Enum.find(table.players, fn(p) -> p.position == "south" end)
    call_204("/board/#{table_id}/a/place?player=#{south.name}", %{index: 1, x: 0, y: 0})
  end

  test "new with config" do
    %{id: table_id} = call_200("/table/new", %{"configuration" => "beta"})
    call_204("/table/#{table_id}/a/join", %{player: "p1"})
    table = get_200("/table/#{table_id}/state")
    assert table.configuration == "Elixir.Yagg.Board.Configuration.Chain"
    call_204("/table/#{table_id}/a/join", %{player: "p2"})
    table = get_200("/table/#{table_id}/state")
    assert table.board.grid[:"2,2"] == "block"
  end

  test "with ai" do
    %{id: table_id} = call_200("/table/new", %{"configuration" => "beta"})
    call_204("/table/#{table_id}/a/join", %{player: "p1"})
    table = get_200("/table/#{table_id}/state")
    assert [%{name: "p1"}] = table.players
    call_204("/table/#{table_id}/a/ai", %{name: "random"})
    table = get_200("/table/#{table_id}/state")
    assert [_, _] = table.players
    stop_ai_servers()
  end

  test "two ai" do
    %{id: table_id} = call_200("/table/new", %{"configuration" => "beta"})
    {:ok, subr} = GenServer.start_link(Subscribor, [table_id, "player1"])
    call_204("/table/#{table_id}/a/join", %{player: "p1"})
    table = get_200("/table/#{table_id}/state")
    assert [%{name: "p1"}] = table.players
    assert %{kind: :player_joined} = GenServer.call(subr, :recieve_event)
    call_204("/table/#{table_id}/a/ai", %{name: "random"})
    table = get_200("/table/#{table_id}/state")
    assert [_, _] = table.players
    assert %{kind: :player_joined} = GenServer.call(subr, :recieve_event)
    assert %{kind: :game_started} = GenServer.call(subr, :recieve_event)
    assert %{kind: :player_ready} = GenServer.call(subr, {:find_event, :player_ready})

    %{id: table_id} = call_200("/table/new", %{"configuration" => "beta"})
    call_204("/table/#{table_id}/a/join", %{player: "p1"})
    call_204("/table/#{table_id}/a/ai", %{name: "random"})
    table = get_200("/table/#{table_id}/state")
    assert [_, _] = table.players
    assert "random" == table.board.ready
    stop_ai_servers()
  end

  defp stop_ai_servers() do
    Enum.map(
      Supervisor.which_children(Yagg.AISupervisor),
      fn ({id, _, _, _}) -> Supervisor.terminate_child(Yagg.AISupervisor, id) end
    )
  end
end
