alias Yagg.{Table, Event, Board, Bugreport}
alias Plug.Conn
alias Yagg.Board.Configuration

defmodule Yagg.Endpoint do
  use Plug.Router

  plug(
    CORSPlug,
    origin: ["https://jisaacstone.itch.io", "https://yagg-game.com", "http://jelly.jisaacstone.com", ~r"https://\w+\.ssl\.hwcdn\.net"],
    headers: ["x-userid" | CORSPlug.defaults()[:headers]]
  )
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

  post "/player/guest" do
    {:ok, body, conn} = Conn.read_body(conn)
    data = Poison.Parser.parse!(body, %{keys: :atoms!})
    name = data.name
    player = case Map.get(data, :id) do
      :nil -> Table.Player.new(name)
      id -> Table.Player.renew(name, id)
    end
    respond(conn, 200, player)
  end

  get "/player/:id" do
    id |> String.to_integer() |> Table.Player.fetch() |> to_response(conn)
  end

  post "/table/new" do
    {:ok, body, conn} = Conn.read_body(conn)
    data = Poison.Parser.parse!(body, %{keys: :atoms!})
    config = if Map.has_key?(data, :configuration) do
      Enum.find(Configuration.all(), fn(c) -> c.name == data.configuration end).module
    else
      Configuration.Random
    end
    {:ok, %{id: table_id}} = Table.new(config)
    respond(conn, 200, %{id: table_id})
  end

  get "/table" do
    tables = Table.list() |> Enum.map(
      fn (id) ->
        {:ok, table} = Table.get_state(id)
        %{id: id, players: table.players, config: table.configuration, state: state(table.board)}
      end
    )
    respond(conn, 200, %{tables: tables})
  end

  def state(%Yagg.Jobfair{}), do: :jobfair
  def state(%{state: :battle}), do: :battle
  def state(%{state: %{__struct__: stst}}), do: Module.split(stst) |> Enum.reverse() |> hd() |> String.downcase()
  def state(other), do: other

  post "/board/:table_id/a/:action" do
    case prep_action(Board.Action, action, conn) do
      {:err, _} = err -> err
      {player_name, actiondata} -> Table.board_action(table_id, player_name, actiondata)
    end |> to_response(conn)
  end

  post "/table/:table_id/a/:action" do
    case prep_action(Table.Action, action, conn) do
      {:err, _} = err -> err
      {player_name, actiondata} -> Table.table_action(table_id, player_name, actiondata)
    end |> to_response(conn)
  end

  get "/table/:table_id/state" do
    Table.get_state(table_id) |> to_response(conn)
  end

  post "/table/:table_id/report" do
    {:ok, body, conn} = Conn.read_body(conn)
    {:ok, params} = Poison.decode(body)
    {:ok, state} = Table.get_state(table_id)
    Bugreport.report(
      state.board,
      state.history,
      Map.get(params, "moves", 3),
      params["report"],
      params["meta"]
    ) |> to_response(conn)
  end

  get "/board/:table_id/player_state" do
    case get_player(conn) do
      :error -> {:err, :no}
      id -> Table.get_player_state(table_id, id)
    end |> to_response(conn)
  end

  get "/configurations" do
    respond(conn, 200, Board.Configuration.all())
  end

  get "/units" do
    respond(conn, 200, Board.Configuration.units())
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

  defp prep_action(namespace, action, conn) do
    try do
      module_name = to_module(namespace, action)
      {:ok, body, conn} = Conn.read_body(conn)
      conn = Conn.fetch_query_params(conn)
      actiondata = Poison.decode!(body, as: struct(module_name))
      player = case Map.get(actiondata, :player) do
        :nil -> get_player(conn)
        name -> name
      end
      {player, actiondata}
    rescue
      e in ArgumentError ->
        IO.inspect(e)
        {:err, :unknown_action}
      e in Poison.ParseError ->
        IO.inspect(e)
        {:err, :malformed_request}
    end
  end

  defp get_player(conn) do
    case Conn.get_req_header(conn, "x-userid") do
      [id_str | _] -> String.to_integer(id_str)
      [] -> :error
    end
  end

  defp to_module(base, name) do
    module_name = Module.safe_concat(base, String.capitalize(name))
    if not Code.ensure_loaded?(module_name) do
      raise ArgumentError, message: "#{module_name} does not exist"
    end
    module_name
  end
end
