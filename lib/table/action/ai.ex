alias Yagg.AI
alias Yagg.Event
alias Yagg.Table.Action
alias Yagg.Table.Player
alias Yagg.Board.Configuration

defmodule Action.Ai do
  defstruct [:name]
  @behaviour Action
  def resolve(_, table, _) do
    check_players(table.players, table)
  end

  defp check_players([], _), do: {:err, :nobody}
  defp check_players([_, _], _), do: {:err, :toomany}
  defp check_players([{position, _} = p1], table) do
    aipos = Player.opposite(position)
    {:ok, robot} = AI.Server.start_ai(table, aipos, "randombot")
    {board, events} = Configuration.setup(table.configuration, table.board)
    {
      %{table | players: [p1, {aipos, robot}], board: board},
      [Event.PlayerJoined.new(name: "randombot", position: aipos) | events]
    }
  end
end
