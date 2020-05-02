alias YaggServer.Actions

defmodule YaggServer.Endpoint do
  use Plug.Router

  # plug(CORSPlug)

  plug(Plug.Parsers,
    parsers: [:json, :urlencoded],
    json_decoder: Poison,
    pass: ["application/json", "application/x-www-form-urlencoded"]
  )

  plug :match
  plug :dispatch

  ## These are for testing
  put "/action" do
    :ok = GenServer.call(
      YaggServer.EventManager,
      {:event, conn.params})
    send_resp(conn, 204, "")
  end

  get "/sse/events" do
    conn =
      conn
      |> put_resp_header("Cache-Control", "no-cache")
      |> put_resp_header("connection", "keep-alive")
      |> put_resp_header("Content-Type", "text/event-stream; charset=utf-8")
      |> send_chunked(200)

    {:ok, conn} = chunk(conn, "event: game_event\ndata: {\"yes\": 0}\n\n")
    :ok = GenServer.call(
      YaggServer.EventManager,
      :subscribe)
    sse_loop(conn, self())
  end
  ## End Testing Routs

  post "/game" do
    resp = Actions.game_action(conn.params)
    conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Poison.encode!(resp))
  end

  get "/game_events/:gid" do
    %{"player" => player} = conn.query_params
    {:ok, pid} = YaggServer.Game.get(gid)
    Process.monitor(pid)
    GenServer.call(pid, {:join, player})
    sse_loop(conn, pid)
  end

  match _ do
    send_resp(conn, 404, "oops")
  end

  defp sse_loop(conn, pid) do
    receive do
      {:event, event} ->
        {:ok, conn} = chunk(conn, "event: game_event\ndata: #{Poison.encode!(event)}\n\n")
        sse_loop(conn, pid)
      {:DOWN, _reference, :process, ^pid, _type} ->
        conn
      other ->
        IO.inspect(['OTHER MESSAGE', other])
        sse_loop(conn, pid)
    end
  end
end
