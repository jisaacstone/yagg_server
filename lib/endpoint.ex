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

  put "/test" do
    YaggServer.EventManager.sync_notify(conn.params)
    send_resp(conn, 204, "")
  end

  get "/sse/events" do
    conn =
      conn
      |> put_resp_header("Cache-Control", "no-cache")
      |> put_resp_header("connection", "keep-alive")
      |> put_resp_header("Content-Type", "text/event-stream; charset=utf-8")
      |> send_chunked(200)

    chunk(conn, "event: game_event\ndata: {\"yes\": 0}\n\n")
    # can't use start_link because then the function would return and
    # we'd drop the connection.
    # init will create the link with the EventManager
    {:ok, things} = GenStage.init({YaggServer.EventHandler, conn})
    IO.inspect(things)
    # enter_loop turns this process into a GenServer process
    # for some reason not exposed by elixir so we call the erlang module
    :gen_server.enter_loop(YaggServer.EventHandler, [], things)
    conn
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end
