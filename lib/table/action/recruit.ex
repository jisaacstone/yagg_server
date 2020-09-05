alias Yagg.Jobfair
alias Yagg.Event
alias Yagg.Board
alias Yagg.Table

defmodule Yagg.Table.Action.Recruit do
  @enforce_keys [:units]
  defstruct @enforce_keys

  @spec resolve(%{units: [non_neg_integer]}, Table.t, Table.Player.position) :: {:ok, Table.t} | {:err, atom}
  def resolve(%{units: indices}, %{board: %Jobfair{} = jobfair} = table, player) do
    case Jobfair.choose(jobfair, player.position, indices) do
      {:err, _} = err -> err
      {:ok, jobfair} ->
        table = %{table | board: jobfair}
        case Jobfair.everybody_ready?(jobfair) do
          true ->
            initial_setup(table)
          false ->
            {table, [Event.PlayerReady.new(player: player.position)]}
        end
    end
  end
  def resolve(_, _, _) do
    {:err, :badstate}
  end

  defp initial_setup(table) do
    units = %{
      north: Jobfair.chosen(table.board, :north),
      south: Jobfair.chosen(table.board, :south)
    }
    {board, events} = Board.new(table.configuration) |> Board.setup(units)
    {%{table | board: board}, events}
  end
end
