alias Yagg.{Game, Event}
alias Plug.Conn

defmodule Yagg.Endpoint do
  use Plug.Router

  plug(CORSPlug)

  plug :match
  plug :dispatch

  post "/game/create" do
    {:ok, pid} = Yagg.Game.new()
    gid = pid |> :erlang.pid_to_list() |> to_string() |> String.split(".") |> tl |> hd
    respond(conn, 200, %{id: gid})
  end

  post "/game/:gid/action/:action" do
    act_struct = struct(Module.safe_concat(Yagg.Action, String.capitalize(action)))
    {:ok, body, conn} = Conn.read_body(conn)
    conn = Conn.fetch_query_params(conn)
    actiondata = Poison.decode!(body, as: act_struct)
    player_name = Map.get(actiondata, :player, conn.query_params["player"])

    case Game.act(gid, player_name, actiondata) do
      :ok -> respond(conn, 204, "")
      {:ok, resp} -> respond(conn, 200, resp)
      {:err, err} -> respond(conn, 400, err)
      other -> respond(conn, 501, other)
    end
  end

  get "/game/:gid/state" do
    case Game.get_state(gid) do
      {:ok, game} -> respond(conn, 200, game)
      {:err, err} -> respond(conn, 400, err)
      other -> respond(conn, 501, other)
    end
  end

  get "/game/:gid/units/:player" do
    case Game.get_units(gid, player) do
      {:ok, units} -> respond(conn, 200, units)
      {:err, err} -> respond(conn, 400, err)
      other -> respond(conn, 501, IO.inspect(other))
    end
  end

  get "sse/game/:gid/events" do
    conn =
      conn
      |> Conn.fetch_query_params()
      |> put_resp_header("cache-control", "no-cache")
      |> put_resp_header("connection", "keep-alive")
      |> put_resp_header("content-type", "text/event-stream; charset=utf-8")
      |> send_chunked(200)
    {:ok, conn} = chunk(conn, ~s(event: game_event\ndata: {"subscription": "success"}\n\n))

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
    receive do
      %Event{} = event ->
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
