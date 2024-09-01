require Logger
alias Yagg.Event
alias Yagg.Table

defmodule Yagg.Websocket do
  @moduledoc "Handle websocket connectinos"
  @behaviour :cowboy_websocket
  @impl :cowboy_websocket
  def init(req, _state) do
    [table_id, player_str] = String.split(req.path, "/") |> Enum.take(-2)
    player_id = String.to_integer(player_str)
    {:cowboy_websocket, req, %{path: req.path, player: player_id, table_id: table_id}}
  end
  @impl :cowboy_websocket
  def websocket_init(state) do
    case Table.Player.fetch(state.player) do
      {:err, :notfound} ->
        {:stop, state}
      _ ->
        {:ok, pid} = Table.subscribe(state.table_id, state.player)
        {:ok, Map.put(state, :pid, pid)}
    end
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
    Logger.warning("Unexpected websocket message #{msg}")
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
    Logger.warning("Unexpected websocket_info #{ither}")
    {:ok, state}
  end

  @impl :cowboy_websocket
  def terminate(_reason, _req, _state) do
    Logger.warning("Websocket handler terminated")
    :ok
  end
end
