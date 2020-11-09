alias Yagg.AI
alias Yagg.Event
alias Yagg.Table.Action
alias Yagg.Table.Player

defmodule Action.Ai do
  defstruct [:name]
  @behaviour Action
  def resolve(_, table, _) do
    check_players(table.players, table)
  end

  defp check_players([], _), do: {:err, :nobody}
  defp check_players([_, _], _), do: {:err, :toomany}
  defp check_players([{position, _} = p1], table) do
    robot = Player.new("randombot")
    position = Player.opposite(position)
    {:ok, _pid} = DynamicSupervisor.start_child(Yagg.AISupervisor, {AI.Server, [{table.id, robot, position}]})
    {board, events} = table.board.__struct__.setup(table.board)
    {
      %{table | players: [p1, {position, robot}], board: board},
      [Event.PlayerJoined.new(name: robot.name, position: position) | events]
    }
  end
end
