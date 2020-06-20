alias Yagg.Event
alias Yagg.Table

defmodule Yagg.Websocket do
  @behaviour :cowboy_websocket
  @impl :cowboy_websocket
  def init(req, _state) do
    [table_id, player] = String.split(req.path, "/") |> Enum.take(-2)
    {:cowboy_websocket, req, %{path: req.path, player: player, table_id: table_id}}
  end
  @impl :cowboy_websocket
  def websocket_init(state) do
    {:ok, pid} = Table.subscribe(state.table_id, state.player)
    {:ok, Map.put(state, :pid, pid)}
  end

  # Handle 'ping' messages from the browser - reply
  @impl :cowboy_websocket
  def websocket_handle({:text, "ping"}, state) do
    {:reply, :pong, state}
  end
  # Seems unused?
  def websocket_handle({:ping, _}, state) do
    {:reply, :pong, state}
  end

  def websocket_handle(msg, state) do
    IO.inspect([websocket_message: msg])
    {:reply, {:text, "WHO ARE YOU!?"}, state}
  end

  @impl :cowboy_websocket
  def websocket_info(%Event{} = event, state) do
    {:reply, {:text, Poison.encode!(event)}, state}
  end
  
  def websocket_info({:DOWN, _reference, :process, pid, _type}, %{pid: pid} = state) do
    {:ok, state}
  end
  def websocket_info(ither, state) do
    IO.inspect([ws_noexpect: ither])
    {:ok, state}
  end

  @impl :cowboy_websocket
  def terminate(reason, req, _state) do
    IO.inspect(ws_terminate: reason, req: req)
    :ok
  end
end
