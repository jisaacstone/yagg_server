alias YaggServer.EventManager, as: EM

defmodule YaggServer.Actions do
  def game_action(%{"action" => "create"}) do
    {:ok, pid} = DynamicSupervisor.start_child(YaggServer.GameSupervisor, YaggServer.Game)
    gid = :erlang.pid_to_list(pid)  # using pid as id for now....
    :ok = GenServer.call(EM, {:event, %{new_game: gid}})
    {:ok, gid} 
  end
  def game_action(%{"action" => "start", "game" => gid}) do
    pid = :erlang.list_to_pid(gid)
    case GenServer.call(pid, :start) do
      :ok -> GenServer.call(EM, {:event, %{game_start: gid}})
      other -> other
    end
  end
  def game_action(%{"action" => "join", "game" => gid, "player" => player}) do
    pid = :erlang.list_to_pid(gid)
    case GenServer.call(pid, {:join, player}) do
      :ok -> GenServer.call(EM, {:event, %{game_start: gid}})
      other -> other
    end
  end
  def game_action(invalid) do
    IO.inspect(invalid)
    %{err: :malformed}
  end
end
