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
    PubSub.publish(:event, conn.params)
    send_resp(conn, 204, "")
  end

  get "/sse/events" do
    conn =
      conn
      |> put_resp_header("Cache-Control", "no-cache")
      |> put_resp_header("connection", "keep-alive")
      |> put_resp_header("Content-Type", "text/event-stream; charset=utf-8")
      |> send_chunked(200)

    PubSub.subscribe(self(), :event)
    chunk(conn, "event: game_event\ndata: {\"yes\": 1}\n\n")
    sse_loop(conn, self())
  end

  match _ do
    send_resp(conn, 404, "oops")
  end

  defp sse_loop(conn, pid) do
    # receive is what stops the router from processing
    # and waits for an event to come in
    receive do
      # Send updates when :cagg is finished.
      {:event, data} ->
        # Query for updates.
        # Send update.
        chunk(conn, "event: game_event\ndata: #{Poison.encode!(data)}\n\n")

        # Wait for next publish.
        sse_loop(conn, pid)

      # Stop SSE if this conn is actually down.
      # Ignore other processes finishing.
      {:DOWN, _reference, :process, ^pid, _type} ->
        nil

      # Don't stop SSE because of unrelated events.
      _other ->
        sse_loop(conn, pid)
    end
  end
end
