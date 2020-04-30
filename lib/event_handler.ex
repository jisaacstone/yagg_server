defmodule YaggServer.EventHandler do
  use GenStage

  def start_link do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(conn) do
    {:consumer, conn, subscribe_to: [YaggServer.EventManager]}
  end

  def handle_events(events, _from, conn) do
    IO.inspect(['HE  ', events, conn])
    Enum.map(events, &handle_event(conn, &1))
    {:noreply, [], conn}
  end

  defp handle_event(conn, event) do
    Plug.Conn.chunk(
      conn, 
      "event: game_event\ndata: #{Poison.encode!(event)}\n\n")
  end
end
