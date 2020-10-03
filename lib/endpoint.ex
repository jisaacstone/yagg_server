alias Yagg.{Table, Event, Board}
alias Plug.Conn
alias Yagg.Board.Configuration

defmodule Yagg.Endpoint do
  use Plug.Router

  plug(CORSPlug)
  plug(Plug.Static, at: "/fe", from: "./frontend")

  plug :match
  plug :dispatch

  get("/fe") do
    conn
      |> Conn.put_resp_header("location", "/fe/index.html")
      |> send_resp(302, "")
  end
  get("/") do
    conn
      |> Conn.put_resp_header("location", "/fe/index.html")
      |> send_resp(302, "")
  end

  post "/table/new" do
    {:ok, body, conn} = Conn.read_body(conn)
    data = Poison.Parser.parse!(body, %{keys: :atoms!})
    config = if Map.has_key?(data, :configuration) do
      Configuration.all()[data.configuration]
    else
      Configuration.Random
    end
    {:ok, pid} = Table.new(config)
    table_id = pid |> :erlang.pid_to_list() |> to_string() |> String.split(".") |> tl |> hd
    respond(conn, 200, %{id: table_id})
  end

  get "/table" do
    tables = Table.list() |> Enum.map(
      fn (pid) ->
        id = pid |> :erlang.pid_to_list() |> to_string() |> String.split(".") |> tl |> hd
        {:ok, table} = Table.get_state(pid)
        %{id: id, players: table.players}
      end
    )
    respond(conn, 200, %{tables: tables})
  end

  post "/board/:table_id/a/:action" do
    module_name = Module.safe_concat(Board.Action, String.capitalize(action))
    {:ok, body, conn} = Conn.read_body(conn)
    conn = Conn.fetch_query_params(conn)
    movedata = Poison.decode!(body, as: struct(module_name))
    player_name = Map.get(movedata, :player, conn.query_params["player"])

    Table.board_action(table_id, player_name, movedata) |> to_response(conn)
  end

  post "/table/:table_id/a/:action" do
    module_name = Module.safe_concat(Table.Action, String.capitalize(action))
    {:ok, body, conn} = Conn.read_body(conn)
    conn = Conn.fetch_query_params(conn)
    actiondata = Poison.decode!(body, as: struct(module_name))
    player_name = Map.get(actiondata, :player, conn.query_params["player"])

    Table.table_action(table_id, player_name, actiondata) |> to_response(conn)
  end

  get "/table/:table_id/state" do
    Table.get_state(table_id) |> to_response(conn)
  end

  post "/table/:table_id/report" do
    {:ok, body, conn} = Conn.read_body(conn)
    {:ok, params} = Poison.decode(body)
    {:ok, state} = Table.get_state(table_id)
    bugreport(state.board, state.history, Map.get(params, "moves", 3), params["report"], params["meta"]) |> to_response(conn)
  end

  get "/board/:table_id/player_state/:player_name" do
    Table.get_player_state(table_id, player_name) |> to_response(conn)
  end

  get "/configurations" do
    respond(conn, 200, Board.Configuration.all())
  end

  get "sse/table/:table_id/events" do
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
      _ -> :spectate
    end
    {:ok, pid} = Table.subscribe(table_id, player)
    sse_loop(conn, pid)
  end

  match _ do
    send_resp(conn, 404, "oops")
  end

  # TODO: get notification when EventSource disconnects
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

  defp to_response(result, conn) do
    case result do
      :ok -> respond(conn, 204, "")
      {:ok, resp} -> respond(conn, 200, resp)
      {:err, err} -> respond(conn, 400, %{error: err})
      # other -> respond(conn, 501, %{unexpected: other})
    end
  end

  defp respond(conn, code, data) do
    conn
      |> put_resp_content_type("application/json")
      |> send_resp(code, Poison.encode!(data))
  end

  defp bugreport(board, history, moves, report, meta) do
    {:ok, file} = File.open('bugreports', [:append])
    _ = IO.inspect(file, report, label: "report")
    _ = IO.inspect(file, DateTime.utc_now(), [])
    _ = IO.inspect(file, meta, pretty: :true)
    _ = IO.inspect(file, board, pretty: :true, width: :infinity)
    history
    |> Enum.take(moves)
    |> Enum.each(
      fn({board, action}) ->
        {
          IO.inspect(file, action, pretty: :true, width: :infinity),
          IO.inspect(file, board, pretty: :true, width: :infinity)
        }
      end
    )
  end
end
