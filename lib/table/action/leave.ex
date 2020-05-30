alias Yagg.Table
alias Yagg.Event

defmodule Table.Action.Leave do
  defstruct []
  @behaviour Table.Action

  @impl Table.Action
  def resolve(%{}, game, %Table.Player{} = player) do
    case Enum.find_index(game.players, fn(p) -> p.name == player.name end) do
      :nil ->
        {[], game}
      index ->
        {
          %{game | players: List.delete_at(game.players, index)},
          [Event.new(:player_left, player: player.position, name: player.name)],
        }
    end
  end
  def resolve(%{}, game, :notfound) do
    {[], game}
  end
end
