alias Yagg.Game

defmodule Yagg.Endpoint do
  use Plug.Router

  # plug(CORSPlug)

  plug(Plug.Parsers,
    parsers: [:json, :urlencoded],
    json_decoder: Poison,
    pass: ["application/json", "application/x-www-form-urlencoded"]
  )

  plug :match
  plug :dispatch

  post "/game/create" do
    {:ok, pid} = Yagg.Game.new()
    gid = pid |> :erlang.pid_to_list() |> to_string() |> String.split(".") |> tl |> hd
    respond(conn, 200, %{id: gid})
  end

  post "/game/:gid/action" do
    %{"player" => player} = conn.query_params
    case Game.act(gid, player, conn.params) do
      {:ok, resp} -> respond(conn, 200, resp)
      {:err, err} -> respond(conn, 400, err)
      other -> respond(conn, 501, other)
    end
  end

  get "/game/:gid/state" do
    case Game.get_state(gid) do
      {:ok, state} -> respond(conn, 200, state)
      {:err, err} -> respond(conn, 400, err)
      other -> respond(conn, 501, other)
    end
  end

  get "sse/game/:gid/events" do
    conn =
      conn
      |> put_resp_header("cache-control", "no-cache")
      |> put_resp_header("connection", "keep-alive")
      |> put_resp_header("content-type", "text/event-stream; charset=utf-8")
      |> send_chunked(200)
    {:ok, conn} = chunk(conn, ~s(event: info\ndata: {"subscription": "success"}\n\n))

    player = case conn.query_params do
      %{"player" => p} -> p
      :default -> :spectate
    end
    {:ok, pid} = Game.subscribe(gid, player)
    sse_loop(conn, pid)
  end

  match _ do
    send_resp(conn, 404, "oops")
  end

  defp sse_loop(conn, pid) do
    IO.inspect(['in the loop', pid])
    receive do
      %{event: _} = event ->
        {:ok, conn} = chunk(conn, "event: game_event\ndata: #{Poison.encode!(event)}\n\n")
        sse_loop(conn, pid)
      {:DOWN, _reference, :process, ^pid, _type} ->
        conn
      other ->
        IO.inspect(['OTHER MESSAGE', other])
        sse_loop(conn, pid)
    end
  end

  defp respond(conn, code, data) do
    conn
      |> put_resp_content_type("application/json")
      |> send_resp(code, Poison.encode!(data))
  end
end
